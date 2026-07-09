import json
import time
from typing import Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from pydantic import ValidationError

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.media_api import MediaApiClient
from app.clients.memory_api import MemoryApiClient, MemoryApiUnavailable
from app.clients.model_runtime import ModelRuntimeClient, ModelRuntimeUnavailable
from app.clients.prompt_interpreter import PromptInterpreterClient
from app.config import get_settings
from app.media_dashboard import build_media_dashboard
from app.output_cards import (
    build_output_cards,
    find_output_card_by_id,
    load_output_card_metadata,
    preview_media_type_for_path,
    safe_preview_path_for_card,
)
from app.reference_boards import (
    REFERENCE_BOARDS_ROOT,
    add_item_to_reference_board,
    board_path_for_id,
    build_empty_reference_board,
    build_reference_board_json_export,
    item_id_for_card_id,
    list_reference_boards,
    load_reference_board,
    remove_item_from_reference_board,
    sanitize_board_id,
    update_reference_board_item,
    utc_now_iso,
    write_reference_board,
)
from app.models.gateway import (
    GatewayChatRequest,
    GatewayChatProxyRequest,
    GatewayChatProxyResponse,
    GatewayChatResponse,
    GatewayCodeAskRequest,
    GatewayCodeAskResponse,
    GatewayCodeContextRequest,
    GatewayCodeContextResponse,
    GatewayCodeDiffSuggestRequest,
    GatewayCodeDiffSuggestResponse,
    GatewayCodePatchPlanRequest,
    GatewayCodePatchPlanResponse,
    GatewayFeedbackRequest,
    GatewayFeedbackResponse,
    GatewayFeedbackStatusResponse,
    GatewayHealthResponse,
    GatewayMediaDryRunJobRequest,
    GatewayMediaHealthResponse,
    GatewayMediaJobResponse,
    GatewayMediaPlanRequest,
    GatewayMediaPlanResponse,
    GatewayMediaRealJobRequest,
    GatewayMediaSafety,
    GatewayModelRoutingResponse,
    GatewayModelsResponse,
    GatewayRouteRequest,
    GatewayRouteResponse,
    GatewayRuntimeProfileCompatibilityMatrixResponse,
    GatewayRuntimeProfilePreflightResponse,
    GatewayRuntimeProfileRecommendationSummaryResponse,
    GatewayRuntimeProfileRunCatalogResponse,
    GatewayRuntimeStatusResponse,
    GatewayRuntimeSwitchPlanRequest,
    GatewayRuntimeSwitchPlanResponse,
    GatewayToolExecuteRequest,
    GatewayToolExecuteResponse,
    GatewayToolsResponse,
    GatewayWorkspaceContextRequest,
    GatewayWorkspaceContextResponse,
    GatewayWorkspaceFileResponse,
    GatewayWorkspaceSearchRequest,
    GatewayWorkspaceSearchResponse,
    GatewayWorkspaceStatusResponse,
    GatewayWorkspaceTreeResponse,
    OpenAIChatCompletionChoice,
    OpenAIChatCompletionRequest,
    OpenAIChatCompletionResponse,
    OpenAIChatCompletionUsage,
    OpenAIChatMessage,
    ReferenceBoardAddItemRequest,
    ReferenceBoardCreateRequest,
    ReferenceBoardUpdateItemRequest,
)
from app.services.media_planner import local_media_plan
from app.services.model_mapping import ModelMapping, get_model_mapping
from app.services.chat_proxy import (
    GatewayChatProxyUnavailable,
    fetch_llama_models,
    proxy_chat_to_llama,
)
from app.services.chat_router import classify_chat_intent
from app.services.feedback_capture import append_feedback, feedback_status
from app.services.memory_injection import build_memory_injected_request
from app.services.memory_approval_dashboard import build_memory_approval_dashboard
from app.services.patch_planner import (
    diff_suggest_system_prompt,
    parse_diff_suggestion,
    parse_patch_plan,
    patch_plan_system_prompt,
)
from app.services.repo_agent import RepoAgentService
from app.services.runtime_dashboard import build_runtime_dashboard
from app.services.runtime_profile_compatibility_matrix import (
    build_runtime_profile_compatibility_matrix,
)
from app.services.runtime_profile_dashboard_summary import (
    build_runtime_profile_dashboard_summary,
)
from app.services.runtime_profile_operator_checklist import (
    build_runtime_profile_operator_checklist,
)
from app.services.runtime_profile_preflight import build_runtime_profile_preflight
from app.services.runtime_profile_recommendation_summary import (
    build_runtime_profile_recommendation_summary,
)
from app.services.runtime_profile_run_catalog import build_runtime_profile_run_catalog
from app.services.router import RouteDecision, route_message
from app.services.tool_executor import execute_tool
from app.services.tool_planner import tool_catalog
from app.services.workspace import WorkspaceService

app = FastAPI(title="MoE Gateway API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:8500", "http://localhost:8500"],
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Accept", "Origin", "Authorization"],
)


MEDIA_NEXT_STEPS = [
    "Use /gateway/media/jobs/dry-run to create a dry-run media job.",
    "Real generation requires explicit guarded enablement.",
]


@app.get("/gateway/health", response_model=GatewayHealthResponse)
async def health() -> GatewayHealthResponse:
    settings = get_settings()
    dependencies = {
        "memory_api": await MemoryApiClient(settings.memory_api_url).check(),
        "embed_worker": await EmbedWorkerClient(settings.embed_worker_url).check(),
        "model_runtime": await ModelRuntimeClient(settings.model_runtime_url).check(),
    }
    return GatewayHealthResponse(
        service=settings.service_name,
        status="ok",
        dependencies=dependencies,
    )


@app.get("/gateway/media/health", response_model=GatewayMediaHealthResponse)
async def media_health() -> GatewayMediaHealthResponse:
    settings = get_settings()
    media_status = await MediaApiClient(settings.media_api_url).check()
    interpreter_status = await PromptInterpreterClient(settings.prompt_interpreter_url).check()
    warnings: list[str] = []
    if media_status != "ok":
        warnings.append(f"Media API unreachable: {media_status}")
    if interpreter_status != "ok":
        warnings.append(f"Prompt Interpreter unreachable: {interpreter_status}")

    return GatewayMediaHealthResponse(
        status="ok",
        service="gateway-media",
        media_enabled=settings.gateway_media_enabled,
        real_allowed=settings.gateway_media_real_allowed,
        default_mode=settings.gateway_media_default_mode,
        media_api_url=settings.media_api_public_url,
        prompt_interpreter_url=settings.prompt_interpreter_url,
        media_api_reachable=media_status == "ok",
        prompt_interpreter_reachable=interpreter_status == "ok",
        warnings=warnings,
        safety=_media_safety(),
    )


@app.post("/gateway/media/plan", response_model=GatewayMediaPlanResponse)
async def media_plan(request: GatewayMediaPlanRequest) -> GatewayMediaPlanResponse:
    settings = get_settings()
    if not settings.gateway_media_enabled:
        return GatewayMediaPlanResponse(
            status="rejected",
            mode="dry_run",
            classification={},
            job_spec={},
            warnings=["GATEWAY_MEDIA_ENABLED must be true for media planning."],
            next_steps=[],
        )

    plan = await _build_media_plan(
        prompt=request.prompt,
        target_mode=request.target_mode,
        style=request.style,
    )
    return GatewayMediaPlanResponse(
        status="ok",
        mode="dry_run",
        classification=dict(plan.get("classification") or {}),
        job_spec=dict(plan.get("job_spec") or {}),
        warnings=list(plan.get("warnings") or []),
        next_steps=MEDIA_NEXT_STEPS,
    )


@app.post("/gateway/media/jobs/dry-run", response_model=GatewayMediaJobResponse)
async def media_job_dry_run(
    request: GatewayMediaDryRunJobRequest,
) -> GatewayMediaJobResponse:
    settings = get_settings()
    if not settings.gateway_media_enabled:
        return GatewayMediaJobResponse(
            status="rejected",
            mode="dry_run",
            reason="GATEWAY_MEDIA_ENABLED must be true for media jobs",
            safety=_media_safety(),
        )

    plan = await media_plan(
        GatewayMediaPlanRequest(
            prompt=request.prompt,
            target_mode=request.target_mode,
            style=request.style,
        )
    )
    job_spec = dict(plan.job_spec)
    job_spec["mode"] = "dry_run"
    media_response = await MediaApiClient(settings.media_api_url).create_job(job_spec)
    return GatewayMediaJobResponse(
        status=str(media_response.get("status") or "rejected"),
        mode="dry_run",
        plan=plan,
        media_api=media_response,
        reason=media_response.get("reason") if isinstance(media_response.get("reason"), str) else None,
        safety=_media_safety(),
    )


@app.post("/gateway/media/jobs/real", response_model=GatewayMediaJobResponse)
async def media_job_real(request: GatewayMediaRealJobRequest) -> GatewayMediaJobResponse:
    settings = get_settings()
    if not settings.gateway_media_real_allowed:
        return GatewayMediaJobResponse(
            status="rejected",
            mode="real",
            reason="GATEWAY_MEDIA_REAL_ALLOWED must be true for real generation",
            safety=_media_safety(),
        )
    if not request.confirm_real_generation:
        return GatewayMediaJobResponse(
            status="rejected",
            mode="real",
            reason="confirm_real_generation=true is required for real generation",
            safety=_media_safety(),
        )

    plan = await media_plan(
        GatewayMediaPlanRequest(
            prompt=request.prompt,
            target_mode=request.target_mode,
            style=request.style,
        )
    )
    job_spec = dict(plan.job_spec)
    job_spec["mode"] = "real"
    metadata = dict(job_spec.get("metadata") or {})
    metadata["engine"] = "comfyui"
    metadata["source"] = "gateway-guarded-real"
    job_spec["metadata"] = metadata
    media_response = await MediaApiClient(settings.media_api_url).create_job(job_spec)
    return GatewayMediaJobResponse(
        status=str(media_response.get("status") or "rejected"),
        mode="real",
        plan=plan,
        media_api=media_response,
        reason=media_response.get("reason") if isinstance(media_response.get("reason"), str) else None,
        safety=_media_safety(),
    )


@app.get("/gateway/media/jobs/{job_id}")
async def media_job_status(job_id: str) -> dict[str, Any]:
    settings = get_settings()
    return await MediaApiClient(settings.media_api_url).get_job(job_id)


@app.get("/gateway/media/dashboard")
async def media_dashboard() -> dict[str, Any]:
    settings = get_settings()
    if not settings.media_dashboard_enabled:
        return {
            "status": "rejected",
            "service": "gateway-media-dashboard",
            "reason": "MEDIA_DASHBOARD_ENABLED must be true",
            "safety": {
                "read_only": True,
                "starts_services": False,
                "stops_services": False,
                "real_generation_trigger": False,
                "arbitrary_shell": False,
            },
        }
    return await build_media_dashboard(settings)


@app.get("/gateway/media/output-cards")
async def media_output_cards() -> dict[str, Any]:
    return build_output_cards()


@app.get("/gateway/media/output-preview/{card_id:path}", response_model=None)
async def media_output_preview(card_id: str) -> FileResponse | JSONResponse:
    card = find_output_card_by_id(card_id)
    if card is None:
        return _preview_error(
            404,
            "preview_unavailable",
            "No allowlisted output card matched the requested card_id.",
        )

    preview_path, error = safe_preview_path_for_card(card)
    if error == "preview_unavailable":
        return _preview_error(
            404,
            "preview_unavailable",
            "Preview is not available for this card type.",
        )
    if error is not None or preview_path is None:
        return _preview_error(
            403,
            "preview_blocked",
            "Preview blocked by safety policy.",
        )

    media_type = preview_media_type_for_path(preview_path)
    if media_type is None:
        return _preview_error(
            403,
            "preview_blocked",
            "Preview blocked by safety policy.",
        )

    return FileResponse(
        path=preview_path,
        media_type=media_type,
        headers={"Cache-Control": "no-store"},
    )


@app.get("/gateway/media/output-card-metadata/{card_id:path}", response_model=None)
async def media_output_card_metadata(card_id: str) -> dict[str, Any] | JSONResponse:
    card = find_output_card_by_id(card_id)
    if card is None:
        return _metadata_error(
            404,
            "metadata_unavailable",
            "No metadata sidecar is available for this card.",
        )

    metadata, error = load_output_card_metadata(card)
    if error == "metadata_unavailable":
        return _metadata_error(
            404,
            "metadata_unavailable",
            "No metadata sidecar is available for this card.",
        )
    if error == "metadata_invalid":
        return _metadata_error(
            422,
            "metadata_invalid",
            "Metadata sidecar is not valid JSON.",
        )
    if error is not None or metadata is None:
        return _metadata_error(
            403,
            "metadata_blocked",
            "Metadata access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-output-card-metadata",
        "card_id": card_id,
        "metadata_available": True,
        "metadata": metadata,
    }


@app.get("/gateway/media/reference-boards")
async def media_reference_boards() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "safety": _reference_board_safety(),
        "root": str(REFERENCE_BOARDS_ROOT),
        "boards": list_reference_boards(),
    }


@app.get("/gateway/media/reference-boards/{board_id}", response_model=None)
async def media_reference_board(board_id: str) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    try:
        board = load_reference_board(safe_board_id)
    except FileNotFoundError:
        return _reference_board_error(
            404,
            "reference_board_not_found",
            "Reference board not found.",
        )
    except ValueError:
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "board": board,
    }


@app.get("/gateway/media/reference-boards/{board_id}/export/json", response_model=None)
async def media_reference_board_export_json(board_id: str) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    try:
        return build_reference_board_json_export(safe_board_id)
    except FileNotFoundError:
        return _reference_board_error(
            404,
            "reference_board_not_found",
            "Reference board not found.",
        )
    except ValueError:
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )


@app.post("/gateway/media/reference-boards", status_code=201, response_model=None)
async def media_reference_board_create(request: ReferenceBoardCreateRequest) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(request.board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    title = request.title.strip()
    description = request.description.strip() if request.description is not None else None
    if not title:
        return _reference_board_error(
            400,
            "invalid_reference_board",
            "Reference board title is required.",
        )

    path = board_path_for_id(safe_board_id)
    if path.exists():
        return _reference_board_error(
            409,
            "reference_board_conflict",
            "Reference board already exists.",
        )

    board = build_empty_reference_board(
        board_id=safe_board_id,
        title=title,
        description=description,
    )
    try:
        write_reference_board(board)
        created = load_reference_board(safe_board_id)
    except ValueError:
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "board": created,
    }


@app.post("/gateway/media/reference-boards/{board_id}/items", response_model=None)
async def media_reference_board_add_item(
    board_id: str,
    request: ReferenceBoardAddItemRequest,
) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    try:
        load_reference_board(safe_board_id)
    except FileNotFoundError:
        return _reference_board_error(
            404,
            "reference_board_not_found",
            "Reference board not found.",
        )
    except ValueError:
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    card = find_output_card_by_id(request.card_id)
    if card is None:
        return _reference_board_error(
            404,
            "output_card_not_found",
            "Output card not found.",
        )

    item = _reference_board_item_from_card(
        card=card,
        selected_reason=request.selected_reason,
        request_tags=request.tags,
    )
    try:
        board = add_item_to_reference_board(safe_board_id, item)
    except ValueError as exc:
        if str(exc) == "reference_board_item_exists":
            return _reference_board_error(
                409,
                "reference_board_item_exists",
                "Output card is already selected in this board.",
            )
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "board": board,
        "item": item,
    }


@app.delete("/gateway/media/reference-boards/{board_id}/items/{item_id}", response_model=None)
async def media_reference_board_remove_item(board_id: str, item_id: str) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    try:
        board = remove_item_from_reference_board(safe_board_id, item_id)
    except FileNotFoundError:
        return _reference_board_error(
            404,
            "reference_board_not_found",
            "Reference board not found.",
        )
    except ValueError as exc:
        if str(exc) == "reference_board_item_not_found":
            return _reference_board_error(
                404,
                "reference_board_item_not_found",
                "Reference board item not found.",
            )
        if str(exc) == "invalid_item_id":
            return _reference_board_error(
                400,
                "invalid_item_id",
                "Invalid reference board item id.",
            )
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "board": board,
        "removed_item_id": item_id,
    }


@app.patch("/gateway/media/reference-boards/{board_id}/items/{item_id}", response_model=None)
async def media_reference_board_update_item(
    board_id: str,
    item_id: str,
    request_data: dict[str, Any],
) -> dict[str, Any] | JSONResponse:
    try:
        safe_board_id = sanitize_board_id(board_id)
    except ValueError:
        return _reference_board_error(
            400,
            "invalid_board_id",
            "Invalid reference board id.",
        )

    try:
        request = ReferenceBoardUpdateItemRequest.model_validate(request_data)
    except ValidationError as exc:
        error_text = str(exc)
        if "No editable item fields were provided" in error_text:
            return _reference_board_error(
                400,
                "invalid_item_update",
                "No editable item fields were provided.",
            )
        return _reference_board_error(
            400,
            "invalid_item_update",
            "Invalid reference board item update.",
        )

    updates = request.model_dump(exclude_unset=True)
    try:
        board, item = update_reference_board_item(safe_board_id, item_id, updates)
    except FileNotFoundError:
        return _reference_board_error(
            404,
            "reference_board_not_found",
            "Reference board not found.",
        )
    except ValueError as exc:
        if str(exc) == "reference_board_item_not_found":
            return _reference_board_error(
                404,
                "reference_board_item_not_found",
                "Reference board item not found.",
            )
        if str(exc) == "invalid_item_update":
            return _reference_board_error(
                400,
                "invalid_item_update",
                "No editable item fields were provided.",
            )
        if str(exc) == "invalid_item_id":
            return _reference_board_error(
                400,
                "invalid_item_id",
                "Invalid reference board item id.",
            )
        return _reference_board_error(
            403,
            "reference_board_blocked",
            "Reference board access blocked by safety policy.",
        )

    return {
        "status": "ok",
        "service": "gateway-reference-boards",
        "board": board,
        "item": item,
    }


@app.get("/gateway/runtime/dashboard")
async def runtime_dashboard() -> dict[str, Any]:
    settings = get_settings()
    if not settings.runtime_dashboard_enabled:
        return {
            "status": "rejected",
            "service": "gateway-runtime-dashboard",
            "reason": "RUNTIME_DASHBOARD_ENABLED must be true",
            "safety": {
                "read_only": True,
                "starts_services": False,
                "stops_services": False,
                "real_generation_trigger": False,
                "arbitrary_shell": False,
            },
        }
    return await build_runtime_dashboard(settings)


@app.get(
    "/gateway/runtime/profile-preflight",
    response_model=GatewayRuntimeProfilePreflightResponse,
)
async def runtime_profile_preflight() -> GatewayRuntimeProfilePreflightResponse:
    settings = get_settings()
    return GatewayRuntimeProfilePreflightResponse(
        **await build_runtime_profile_preflight(settings)
    )


@app.get(
    "/gateway/runtime/profile-run-catalog",
    response_model=GatewayRuntimeProfileRunCatalogResponse,
)
async def runtime_profile_run_catalog() -> GatewayRuntimeProfileRunCatalogResponse:
    settings = get_settings()
    return GatewayRuntimeProfileRunCatalogResponse(
        **await build_runtime_profile_run_catalog(settings)
    )


@app.get(
    "/gateway/runtime/profile-compatibility-matrix",
    response_model=GatewayRuntimeProfileCompatibilityMatrixResponse,
)
async def runtime_profile_compatibility_matrix() -> (
    GatewayRuntimeProfileCompatibilityMatrixResponse
):
    settings = get_settings()
    return GatewayRuntimeProfileCompatibilityMatrixResponse(
        **await build_runtime_profile_compatibility_matrix(settings)
    )


@app.get(
    "/gateway/runtime/profile-recommendation-summary",
    response_model=GatewayRuntimeProfileRecommendationSummaryResponse,
)
async def runtime_profile_recommendation_summary() -> (
    GatewayRuntimeProfileRecommendationSummaryResponse
):
    settings = get_settings()
    return GatewayRuntimeProfileRecommendationSummaryResponse(
        **await build_runtime_profile_recommendation_summary(settings)
    )


@app.get("/gateway/runtime/profile-dashboard-summary")
async def runtime_profile_dashboard_summary() -> dict[str, Any]:
    settings = get_settings()
    return await build_runtime_profile_dashboard_summary(settings)


@app.get("/gateway/runtime/profile-operator-checklist")
async def runtime_profile_operator_checklist() -> dict[str, Any]:
    settings = get_settings()
    return await build_runtime_profile_operator_checklist(settings)


@app.get("/gateway/memory-approval/dashboard")
async def memory_approval_dashboard() -> dict[str, Any]:
    return build_memory_approval_dashboard()


@app.post(
    "/gateway/feedback",
    response_model=GatewayFeedbackResponse,
    response_model_exclude_none=True,
)
async def gateway_feedback(
    request: GatewayFeedbackRequest,
) -> GatewayFeedbackResponse:
    settings = get_settings()
    try:
        record = append_feedback(request, settings.gateway_feedback_path)
    except Exception as exc:
        return GatewayFeedbackResponse(
            status="error",
            service="gateway-feedback",
            path=settings.gateway_feedback_path,
            detail=f"feedback append failed: {exc.__class__.__name__}: {exc}",
        )

    return GatewayFeedbackResponse(
        status="ok",
        service="gateway-feedback",
        id=str(record["id"]),
        path=settings.gateway_feedback_path,
    )


@app.get("/gateway/feedback/status", response_model=GatewayFeedbackStatusResponse)
async def gateway_feedback_status() -> GatewayFeedbackStatusResponse:
    settings = get_settings()
    try:
        status = feedback_status(settings.gateway_feedback_path)
    except Exception as exc:
        return GatewayFeedbackStatusResponse(
            status="error",
            service="gateway-feedback",
            path=settings.gateway_feedback_path,
            exists=False,
            record_count=0,
            latest_created_at=None,
            detail=f"feedback status failed: {exc.__class__.__name__}: {exc}",
        )

    return GatewayFeedbackStatusResponse(**status)


@app.get("/gateway/models", response_model=GatewayModelsResponse)
async def models() -> GatewayModelsResponse:
    settings = get_settings()
    client = ModelRuntimeClient(settings.model_runtime_url)
    try:
        model_list = await client.list_models()
    except ModelRuntimeUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return GatewayModelsResponse(
        status="ok",
        model_runtime_url=settings.model_runtime_public_url,
        models=model_list,
    )


@app.get("/gateway/model-routing", response_model=GatewayModelRoutingResponse)
def model_routing() -> GatewayModelRoutingResponse:
    settings = get_settings()
    mapping = get_model_mapping(settings.model_routing_config)
    config = mapping.safe_config()
    return GatewayModelRoutingResponse(status="ok", **config)


@app.get("/gateway/tools", response_model=GatewayToolsResponse)
def tools() -> GatewayToolsResponse:
    return GatewayToolsResponse(
        status="ok",
        tools=tool_catalog(),
        auto_execution_enabled=False,
        read_only_execution_enabled=True,
    )


@app.post(
    "/gateway/tools/execute",
    response_model=GatewayToolExecuteResponse,
    response_model_exclude_none=True,
)
async def tools_execute(
    request: GatewayToolExecuteRequest,
) -> GatewayToolExecuteResponse:
    settings = get_settings()
    result = await execute_tool(
        tool=request.tool,
        arguments=request.arguments,
        settings=settings,
    )
    return GatewayToolExecuteResponse(**result)


@app.get("/gateway/runtime/status", response_model=GatewayRuntimeStatusResponse)
async def runtime_status() -> GatewayRuntimeStatusResponse:
    settings = get_settings()
    client = ModelRuntimeClient(settings.model_runtime_url)
    status = await client.status()
    return GatewayRuntimeStatusResponse(
        status="ok",
        runtime_available=bool(status["runtime_available"]),
        model_runtime_url=settings.model_runtime_public_url,
        loaded_models=status["loaded_models"],
        current_model=status["current_model"],
    )


@app.get("/gateway/workspace/status", response_model=GatewayWorkspaceStatusResponse)
def workspace_status() -> GatewayWorkspaceStatusResponse:
    settings = get_settings()
    return GatewayWorkspaceStatusResponse(**WorkspaceService(settings).status())


@app.get(
    "/gateway/workspace/tree",
    response_model=GatewayWorkspaceTreeResponse,
    response_model_exclude_none=True,
)
def workspace_tree(
    path: str = ".",
    max_items: int | None = None,
) -> GatewayWorkspaceTreeResponse:
    settings = get_settings()
    return GatewayWorkspaceTreeResponse(
        **WorkspaceService(settings).tree(path=path, max_items=max_items)
    )


@app.get(
    "/gateway/workspace/file",
    response_model=GatewayWorkspaceFileResponse,
    response_model_exclude_none=True,
)
def workspace_file(path: str) -> GatewayWorkspaceFileResponse:
    settings = get_settings()
    return GatewayWorkspaceFileResponse(**WorkspaceService(settings).file(path=path))


@app.post(
    "/gateway/workspace/search",
    response_model=GatewayWorkspaceSearchResponse,
    response_model_exclude_none=True,
)
def workspace_search(
    request: GatewayWorkspaceSearchRequest,
) -> GatewayWorkspaceSearchResponse:
    settings = get_settings()
    return GatewayWorkspaceSearchResponse(
        **WorkspaceService(settings).search(
            query=request.query,
            path=request.path,
            max_results=request.max_results,
        )
    )


@app.post(
    "/gateway/workspace/context",
    response_model=GatewayWorkspaceContextResponse,
)
def workspace_context(
    request: GatewayWorkspaceContextRequest,
) -> GatewayWorkspaceContextResponse:
    settings = get_settings()
    return GatewayWorkspaceContextResponse(
        **WorkspaceService(settings).context(
            task=request.task,
            paths=request.paths,
            max_chars=request.max_chars,
        )
    )


@app.post("/gateway/code/context", response_model=GatewayCodeContextResponse)
def code_context(request: GatewayCodeContextRequest) -> GatewayCodeContextResponse:
    settings = get_settings()
    return GatewayCodeContextResponse(
        **RepoAgentService(settings).build_context(
            task=request.task,
            query=request.query,
            paths=request.paths,
            max_files=request.max_files,
            max_chars=request.max_chars,
        )
    )


@app.post(
    "/gateway/code/ask",
    response_model=GatewayCodeAskResponse,
    response_model_exclude_none=True,
)
async def code_ask(request: GatewayCodeAskRequest) -> GatewayCodeAskResponse:
    settings = get_settings()
    context = RepoAgentService(settings).build_context(
        task=request.task,
        query=request.query,
        paths=request.paths,
        max_files=request.max_files,
        max_chars=request.max_context_chars,
    )
    system = "\n\n".join(
        [
            "You are a repo-aware coding assistant.",
            "Use the provided read-only repository context.",
            "Do not claim files were edited.",
            "When suggesting changes, describe them or provide patch-style suggestions only.",
            str(context["context"]),
        ]
    )
    try:
        chat_response = await _gateway_chat(
            GatewayChatRequest(
                message=request.task,
                system=system,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                use_memory=request.use_memory,
                auto_route=request.auto_route,
            )
        )
    except HTTPException as exc:
        if exc.status_code == 503:
            return GatewayCodeAskResponse(
                status="unavailable",
                selected_files=context["selected_files"],
                truncated=bool(context["truncated"]),
                reason=str(exc.detail),
            )
        raise

    return GatewayCodeAskResponse(
        status="ok",
        content=chat_response.content,
        selected_files=context["selected_files"],
        route=chat_response.route,
        memory=chat_response.memory,
        model=chat_response.model,
        truncated=bool(context["truncated"]),
    )


@app.post(
    "/gateway/code/patch-plan",
    response_model=GatewayCodePatchPlanResponse,
    response_model_exclude_none=True,
)
async def code_patch_plan(
    request: GatewayCodePatchPlanRequest,
) -> GatewayCodePatchPlanResponse:
    settings = get_settings()
    context = RepoAgentService(settings).build_context(
        task=request.task,
        query=request.query,
        paths=request.paths,
        max_files=request.max_files,
        max_chars=request.max_context_chars,
    )
    try:
        chat_response = await _gateway_chat(
            GatewayChatRequest(
                message=request.task,
                system=patch_plan_system_prompt(str(context["context"])),
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                use_memory=False,
                auto_route=True,
            )
        )
    except HTTPException as exc:
        if exc.status_code == 503:
            return GatewayCodePatchPlanResponse(
                status="unavailable",
                selected_files=context["selected_files"],
                reason=str(exc.detail),
            )
        raise

    plan = parse_patch_plan(chat_response.content, context["selected_files"])
    return GatewayCodePatchPlanResponse(
        status="ok",
        selected_files=context["selected_files"],
        route=chat_response.route,
        **plan,
    )


@app.post(
    "/gateway/code/diff-suggest",
    response_model=GatewayCodeDiffSuggestResponse,
    response_model_exclude_none=True,
)
async def code_diff_suggest(
    request: GatewayCodeDiffSuggestRequest,
) -> GatewayCodeDiffSuggestResponse:
    settings = get_settings()
    context = RepoAgentService(settings).build_context(
        task=request.task,
        query=request.query,
        paths=request.paths,
        max_files=request.max_files,
        max_chars=request.max_context_chars,
    )
    try:
        chat_response = await _gateway_chat(
            GatewayChatRequest(
                message=request.task,
                system=diff_suggest_system_prompt(str(context["context"])),
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                use_memory=False,
                auto_route=True,
            )
        )
    except HTTPException as exc:
        if exc.status_code == 503:
            return GatewayCodeDiffSuggestResponse(
                status="unavailable",
                apply_supported=False,
                selected_files=context["selected_files"],
                reason=str(exc.detail),
            )
        raise

    suggestion = parse_diff_suggestion(chat_response.content)
    return GatewayCodeDiffSuggestResponse(
        status="ok",
        apply_supported=False,
        selected_files=context["selected_files"],
        route=chat_response.route,
        **suggestion,
    )


@app.post(
    "/gateway/runtime/switch-plan",
    response_model=GatewayRuntimeSwitchPlanResponse,
)
async def runtime_switch_plan(
    request: GatewayRuntimeSwitchPlanRequest,
) -> GatewayRuntimeSwitchPlanResponse:
    settings = get_settings()
    mapping = get_model_mapping(settings.model_routing_config)
    client = ModelRuntimeClient(settings.model_runtime_url)
    status = await client.status()
    intent, requested_target = _switch_plan_target(request, mapping)
    target, target_runtime_id, model_mapping_status, mapping_warning = (
        _resolve_switch_plan_target(requested_target, mapping)
    )
    current_model = status["current_model"]
    active_model_matches_target = bool(
        current_model
        and target_runtime_id
        and current_model == target_runtime_id
    )
    guardrails = [
        "Gateway produced a planning-only runtime switch review.",
        "Gateway did not start, stop, restart, or switch the model runtime.",
        "Gateway performed no terminal, container, filesystem, model-runtime, or memory-write action.",
        "This plan is informational and requires a human operator.",
    ]
    if mapping_warning:
        guardrails.append(mapping_warning)
    if not status["runtime_available"]:
        guardrails.append("Current model runtime status is unavailable or unknown.")
    risk_level = _runtime_switch_plan_risk_level(
        runtime_available=bool(status["runtime_available"]),
        active_model_matches_target=active_model_matches_target,
        model_mapping_status=model_mapping_status,
    )

    return GatewayRuntimeSwitchPlanResponse(
        status="plan_only",
        intent=intent,
        target_model_id=target,
        target_runtime_model_id=target_runtime_id,
        current_active_model=current_model,
        active_model_matches_target=active_model_matches_target,
        risk_level=risk_level,
        model_mapping_status=model_mapping_status,
        guardrails=guardrails,
        preflight_checks=[
            "Confirm no long-running generation or coding task depends on the current runtime.",
            "Confirm the desired model file exists in the documented model inventory.",
            "Confirm enough RAM and VRAM are available for the desired model.",
            "Verify the Gateway and Continue clients can reconnect after a manual runtime change.",
        ],
        manual_next_steps=[
            "Stop the current model runtime manually only after saving work.",
            "Start the desired runtime model using the documented local runbook.",
            "Verify /v1/models before reconnecting Continue.",
            "Return to Gateway chat after confirming the active runtime model.",
        ],
        runbook="docs/gateway-runtime-switch-runbook.md",
        runbook_status="manual_only",
        runbook_required=True,
        verification_steps=[
            "Review the Gateway runtime switch runbook before changing the local runtime.",
            "Confirm /v1/models before and after the manual runtime change.",
            "Confirm Continue still uses the Gateway-Auto profile at http://localhost:8100/v1.",
            "Send a short /v1/chat/completions request after the manual runtime change.",
        ],
        rollback_guidance=(
            "If the new runtime is not healthy, manually return to the previous "
            "known-good local runtime from the operator runbook."
        ),
        reason=_runtime_switch_plan_reason(
            runtime_available=bool(status["runtime_available"]),
            active_model_matches_target=active_model_matches_target,
            model_mapping_status=model_mapping_status,
        ),
    )


@app.post(
    "/gateway/chat",
    response_model=GatewayChatProxyResponse | GatewayChatResponse,
    response_model_exclude_none=True,
)
async def chat(request: dict[str, Any]) -> GatewayChatProxyResponse | GatewayChatResponse:
    if "messages" not in request:
        try:
            legacy_request = GatewayChatRequest(**request)
        except ValidationError as exc:
            raise HTTPException(status_code=400, detail=exc.errors()) from exc
        return await _gateway_chat(legacy_request)

    try:
        proxy_request = GatewayChatProxyRequest(**request)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=exc.errors()) from exc

    _validate_chat_proxy_request(proxy_request)

    if proxy_request.stream:
        raise HTTPException(
            status_code=400,
            detail="streaming is not implemented for /gateway/chat yet",
        )

    return await _gateway_chat_proxy(proxy_request)


@app.get("/v1/models")
async def openai_models() -> dict[str, Any]:
    settings = get_settings()
    try:
        return await fetch_llama_models(settings)
    except GatewayChatProxyUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.post("/v1/chat/completions", response_model=OpenAIChatCompletionResponse)
async def openai_chat_completions(
    request_body: dict[str, Any],
) -> OpenAIChatCompletionResponse | JSONResponse | StreamingResponse:
    try:
        request = OpenAIChatCompletionRequest(**request_body)
    except ValidationError as exc:
        return _openai_error_response(
            status_code=400,
            message=f"invalid OpenAI chat completion request: {exc.errors()}",
            error_type="invalid_request_error",
            code="invalid_request",
        )

    try:
        proxy_request = _openai_to_gateway_chat_proxy_request(request)
    except ValidationError as exc:
        return _openai_error_response(
            status_code=400,
            message=f"invalid Gateway chat proxy request: {exc.errors()}",
            error_type="invalid_request_error",
            code="invalid_request",
        )
    try:
        _validate_chat_proxy_request(proxy_request)
    except HTTPException as exc:
        return _openai_error_response(
            status_code=exc.status_code,
            message=str(exc.detail),
            error_type="invalid_request_error",
            code="invalid_request",
        )

    response = await _gateway_chat_proxy(proxy_request)
    if response.status == "unavailable":
        return _openai_error_response(
            status_code=503,
            message=response.detail or "Gateway chat proxy unavailable",
            error_type="service_unavailable",
            code="gateway_chat_proxy_unavailable",
        )

    raw = response.raw or {}
    usage = raw.get("usage") if isinstance(raw.get("usage"), dict) else {}
    completion = OpenAIChatCompletionResponse(
        id=str(raw.get("id") or f"chatcmpl-local-{uuid4().hex}"),
        object=str(raw.get("object") or "chat.completion"),
        created=int(raw.get("created") or time.time()),
        model=str(response.model or request.model),
        choices=[
            OpenAIChatCompletionChoice(
                index=0,
                message=OpenAIChatMessage(
                    role="assistant",
                    content=response.response or "",
                ),
                finish_reason="stop",
            )
        ],
        usage=OpenAIChatCompletionUsage(**usage),
        x_gateway_router=response.router.model_dump() if response.router else None,
        x_gateway_memory=response.memory,
        x_gateway_compat=_openai_compat_metadata(request),
    )
    if request.stream:
        return StreamingResponse(
            _openai_chat_completion_stream(completion),
            media_type="text/event-stream",
        )
    return completion


async def _gateway_chat_proxy(
    proxy_request: GatewayChatProxyRequest,
) -> GatewayChatProxyResponse:
    settings = get_settings()
    route = classify_chat_intent(
        request=proxy_request,
        mapping=get_model_mapping(settings.model_routing_config),
    )
    memory_result = await build_memory_injected_request(
        request=proxy_request,
        settings=settings,
    )
    try:
        proxied = await proxy_chat_to_llama(memory_result.request, settings)
    except GatewayChatProxyUnavailable as exc:
        return GatewayChatProxyResponse(
            status="unavailable",
            service="gateway-chat-proxy",
            router=route.to_response(active_model=None),
            memory=memory_result.metadata,
            detail=str(exc),
        )

    active_model = proxied.get("active_model")
    if not isinstance(active_model, str):
        active_model = str(proxied["model"])

    return GatewayChatProxyResponse(
        status="ok",
        service="gateway-chat-proxy",
        model=str(proxied["model"]),
        response=str(proxied["content"]),
        router=route.to_response(active_model=active_model),
        memory=memory_result.metadata,
        raw=proxied["raw"],
    )


def _validate_chat_proxy_request(proxy_request: GatewayChatProxyRequest) -> None:
    if any(not message.content.strip() for message in proxy_request.messages):
        raise HTTPException(
            status_code=400,
            detail="message content must be non-empty",
        )


async def _gateway_chat(request: GatewayChatRequest) -> GatewayChatResponse:
    settings = get_settings()
    mapping = get_model_mapping(settings.model_routing_config)
    client = ModelRuntimeClient(settings.model_runtime_url)
    model = request.model or await _detect_model(client, settings.default_model)
    decision = route_message(request.message) if request.auto_route else _default_route()
    route_metadata = _route_metadata(decision, mapping)
    model_alignment = _model_alignment(route_metadata, model)
    use_memory = request.use_memory or (
        request.auto_route and decision.use_memory_recommended
    )
    memory_client = MemoryApiClient(settings.memory_api_url)
    memory = await _memory_context(
        client=memory_client,
        message=request.message,
        use_memory=use_memory,
        limit=request.memory_limit,
    )
    messages: list[dict[str, str]] = []
    if request.system:
        messages.append({"role": "system", "content": request.system})
    if request.auto_route:
        messages.append(
            {"role": "system", "content": _intent_guidance(decision.intent)}
        )
    if memory["context"]:
        messages.append({"role": "system", "content": str(memory["context"])})
    messages.append({"role": "user", "content": request.message})

    try:
        response = await client.chat(
            model=model,
            messages=messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
        )
    except ModelRuntimeUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    content = _extract_content(response)
    raw = {
        "id": response.get("id"),
        "created": response.get("created"),
        "usage": response.get("usage"),
    }
    return GatewayChatResponse(
        status="ok",
        model=model,
        content=content,
        route=route_metadata,
        model_alignment=model_alignment,
        memory=memory["metadata"],
        raw={key: value for key, value in raw.items() if value is not None} or None,
    )


async def _build_media_plan(prompt: str, target_mode: str, style: str) -> dict[str, Any]:
    settings = get_settings()
    interpreter = PromptInterpreterClient(settings.prompt_interpreter_url)
    interpreted, warning = await interpreter.interpret(
        prompt=prompt,
        target_mode=target_mode,
        style=style,
    )
    if interpreted is not None:
        warnings = list(interpreted.get("warnings") or [])
        warnings.append("Prompt Interpreter Worker used when reachable.")
        interpreted["warnings"] = warnings
        return interpreted

    fallback = local_media_plan(prompt=prompt, target_mode=target_mode, style=style)
    if warning:
        warnings = list(fallback.get("warnings") or [])
        warnings.insert(0, warning)
        fallback["warnings"] = warnings
    return fallback


def _preview_error(status_code: int, error: str, detail: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "error",
            "error": error,
            "detail": detail,
        },
    )


def _metadata_error(status_code: int, error: str, detail: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "error",
            "error": error,
            "detail": detail,
        },
    )


def _reference_board_error(status_code: int, error: str, detail: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "error",
            "error": error,
            "detail": detail,
        },
    )


def _reference_board_item_from_card(
    card: dict[str, Any],
    selected_reason: str | None,
    request_tags: list[str] | None,
) -> dict[str, Any]:
    card_tags = card.get("tags") if isinstance(card.get("tags"), list) else []
    tags = _dedupe_strings([*card_tags, *(request_tags or [])])
    return {
        "item_id": item_id_for_card_id(str(card["id"])),
        "card_id": card["id"],
        "asset_type": card.get("type") or "unknown",
        "name": card.get("name") or str(card["id"]),
        "relative_runtime_path": card.get("relative_runtime_path"),
        "metadata_path": card.get("metadata_path"),
        "selected_reason": selected_reason.strip() if isinstance(selected_reason, str) and selected_reason.strip() else None,
        "tags": tags,
        "safety_label": card.get("safety_label") or "visual_reference_only",
        "added_at": utc_now_iso(),
    }


def _dedupe_strings(values: list[Any]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if not isinstance(value, str):
            continue
        normalized = value.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(normalized)
    return result


def _reference_board_safety() -> dict[str, bool]:
    return {
        "read_only_assets": True,
        "starts_services": False,
        "stops_services": False,
        "real_generation_trigger": False,
        "arbitrary_shell": False,
    }


def _media_safety() -> GatewayMediaSafety:
    return GatewayMediaSafety(
        starts_services=False,
        stops_services=False,
        arbitrary_shell=False,
        real_generation_default=False,
    )


@app.post("/gateway/route", response_model=GatewayRouteResponse)
def route(request: GatewayRouteRequest) -> GatewayRouteResponse:
    settings = get_settings()
    mapping = get_model_mapping(settings.model_routing_config)
    decision = route_message(request.message)
    route_metadata = _route_metadata(decision, mapping)
    return GatewayRouteResponse(
        status="ok",
        intent=route_metadata["intent"],
        confidence=route_metadata["confidence"],
        model_target=route_metadata["model_target"],
        model_target_runtime_id=route_metadata["model_target_runtime_id"],
        model_mapping_status=route_metadata["model_mapping_status"],
        use_memory_recommended=route_metadata["use_memory_recommended"],
        memory_enabled=request.use_memory,
        reason=route_metadata["reason"],
        signals=route_metadata["signals"],
        tool_plan=route_metadata["tool_plan"],
    )


async def _detect_model(client: ModelRuntimeClient, default_model: str) -> str:
    try:
        model_list = await client.list_models()
    except ModelRuntimeUnavailable:
        return default_model

    for model in model_list:
        model_id = model.get("id")
        if isinstance(model_id, str) and model_id:
            return model_id
    return default_model


def _extract_content(response: dict[str, Any]) -> str:
    choices = response.get("choices")
    if isinstance(choices, list) and choices:
        first = choices[0]
        if isinstance(first, dict):
            message = first.get("message")
            if isinstance(message, dict):
                content = message.get("content")
                if isinstance(content, str):
                    return content
            text = first.get("text")
            if isinstance(text, str):
                return text
    return ""


def _openai_to_gateway_chat_proxy_request(
    request: OpenAIChatCompletionRequest,
) -> GatewayChatProxyRequest:
    return GatewayChatProxyRequest(
        messages=[
            {"role": message.role, "content": message.content}
            for message in request.messages
        ],
        model=request.model,
        temperature=request.temperature,
        max_tokens=request.max_tokens,
        stream=False,
        routing=request.routing,
        memory=request.memory,
        memory_limit=request.memory_limit,
    )


def _openai_compat_metadata(request: OpenAIChatCompletionRequest) -> dict[str, Any]:
    tools_ignored = bool(request.tools)
    tool_choice_ignored = request.tool_choice is not None
    stream_requested = bool(request.stream)
    return {
        "stream_requested": stream_requested,
        "stream_normalized": False,
        "stream_wrapped": stream_requested,
        "tools_ignored": tools_ignored,
        "tool_choice_ignored": tool_choice_ignored,
    }


async def _openai_chat_completion_stream(
    completion: OpenAIChatCompletionResponse,
):
    compat = completion.x_gateway_compat or {}
    base = {
        "id": completion.id,
        "object": "chat.completion.chunk",
        "created": completion.created,
        "model": completion.model,
        "x_gateway_compat": compat,
    }
    content = ""
    if completion.choices:
        content = completion.choices[0].message.content

    chunks = [
        {
            **base,
            "choices": [
                {
                    "index": 0,
                    "delta": {"role": "assistant"},
                    "finish_reason": None,
                }
            ],
        },
        {
            **base,
            "choices": [
                {
                    "index": 0,
                    "delta": {"content": content},
                    "finish_reason": None,
                }
            ],
        },
        {
            **base,
            "choices": [
                {
                    "index": 0,
                    "delta": {},
                    "finish_reason": "stop",
                }
            ],
        },
    ]

    for chunk in chunks:
        yield f"data: {json.dumps(chunk, separators=(',', ':'))}\n\n"
    yield "data: [DONE]\n\n"


def _openai_error_response(
    *,
    status_code: int,
    message: str,
    error_type: str,
    code: str,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "message": message,
                "type": error_type,
                "code": code,
            }
        },
    )


def _openai_to_gateway_chat_request(
    request: OpenAIChatCompletionRequest,
) -> GatewayChatRequest:
    system_messages = [
        message.content
        for message in request.messages
        if message.role == "system" and message.content.strip()
    ]
    user_messages = [
        message.content
        for message in request.messages
        if message.role == "user" and message.content.strip()
    ]

    if not user_messages:
        raise HTTPException(
            status_code=400,
            detail="at least one user message is required",
        )

    system = "\n\n".join(
        message
        for message in [
            "\n\n".join(system_messages),
            _openai_conversation_context(request.messages),
        ]
        if message
    )
    model = _openai_runtime_model(request.model)
    return GatewayChatRequest(
        message=user_messages[-1],
        system=system or None,
        model=model,
        temperature=request.temperature,
        max_tokens=request.max_tokens,
        use_memory=False,
        auto_route=True,
    )


def _openai_runtime_model(model: str) -> str | None:
    if model == "local-gateway":
        return None

    settings = get_settings()
    runtime_id = get_model_mapping(settings.model_routing_config).runtime_id(model)
    return runtime_id or model


def _openai_conversation_context(messages: list[OpenAIChatMessage]) -> str | None:
    context_lines: list[str] = []
    last_user_index = max(
        (
            index
            for index, message in enumerate(messages)
            if message.role == "user" and message.content.strip()
        ),
        default=-1,
    )

    for index, message in enumerate(messages):
        content = message.content.strip()
        if not content or message.role == "system":
            continue
        if index == last_user_index and message.role == "user":
            continue
        if message.role not in {"user", "assistant"}:
            continue
        context_lines.append(f"{message.role}: {content}")

    if not context_lines:
        return None

    return "Conversation so far:\n" + "\n".join(context_lines)


def _default_route() -> RouteDecision:
    return RouteDecision(
        intent="chat",
        confidence=0.0,
        use_memory_recommended=False,
        reason="Auto routing disabled",
        signals={"matched_keywords": [], "message_length": 0},
        tool_plan={
            "recommended_tools": ["model_chat"],
            "requires_runtime": True,
            "requires_memory": False,
            "safe_to_auto_run": True,
            "reason": "Auto routing disabled; defaulting to model chat.",
        },
    )


def _route_metadata(
    decision: RouteDecision,
    mapping: ModelMapping,
) -> dict[str, Any]:
    target = mapping.target_for_intent(decision.intent)
    return {
        "intent": decision.intent,
        "confidence": decision.confidence,
        "model_target": target["model_target"],
        "model_target_runtime_id": target["model_target_runtime_id"],
        "model_mapping_status": target["model_mapping_status"],
        "use_memory_recommended": decision.use_memory_recommended,
        "reason": decision.reason,
        "signals": decision.signals,
        "tool_plan": decision.tool_plan,
    }


def _model_alignment(
    route_metadata: dict[str, Any],
    actual_model: str,
) -> dict[str, Any]:
    target = str(route_metadata["model_target"])
    target_runtime_id = route_metadata.get("model_target_runtime_id")
    matched = actual_model in {target, target_runtime_id}
    return {
        "target": target,
        "target_runtime_id": target_runtime_id,
        "actual": actual_model,
        "matched": matched,
        "reason": "Actual runtime model matches advisory target"
        if matched
        else "Gateway does not switch runtime models yet",
    }


def _switch_plan_target(
    request: GatewayRuntimeSwitchPlanRequest,
    mapping: ModelMapping,
) -> tuple[str, str]:
    if request.target:
        return request.intent or "manual", request.target

    if request.intent:
        target = mapping.target_for_intent(request.intent)
        return request.intent, str(target["model_target"])

    decision = route_message(request.message)
    target = mapping.target_for_intent(decision.intent)
    return decision.intent, str(target["model_target"])


def _resolve_switch_plan_target(
    requested_target: str,
    mapping: ModelMapping,
) -> tuple[str, str | None, str, str | None]:
    runtime_id = mapping.runtime_id(requested_target)
    if runtime_id:
        return requested_target, runtime_id, "mapped", None

    fallback = mapping.fallback_model_target
    fallback_runtime_id = mapping.runtime_id(fallback)
    if fallback_runtime_id:
        return (
            fallback,
            fallback_runtime_id,
            "fallback_missing_requested_runtime",
            (
                f"Requested target {requested_target} is not mapped to a runtime model; "
                f"planning with fallback target {fallback}."
            ),
        )

    return (
        requested_target,
        None,
        "missing_requested_and_fallback_runtime",
        (
            f"Requested target {requested_target} and fallback target {fallback} "
            "are not mapped to runtime models."
        ),
    )


def _runtime_switch_plan_risk_level(
    *,
    runtime_available: bool,
    active_model_matches_target: bool,
    model_mapping_status: str,
) -> str:
    if "missing" in model_mapping_status:
        return "high"
    if not runtime_available:
        return "medium"
    if active_model_matches_target:
        return "low"
    return "medium"


def _runtime_switch_plan_reason(
    *,
    runtime_available: bool,
    active_model_matches_target: bool,
    model_mapping_status: str,
) -> str:
    if "missing" in model_mapping_status:
        return "Runtime switch planning found a missing model mapping; no action was attempted."
    if not runtime_available:
        return "Runtime is unavailable or unknown; no action was attempted."
    if active_model_matches_target:
        return "Current active runtime model already matches the planned target; no action was attempted."
    return "Planned target differs from active runtime model; no action was attempted."


def _intent_guidance(intent: str) -> str:
    guidance = {
        "chat": "Answer naturally and concisely.",
        "code": "You are in coding mode. Prefer precise, actionable steps. When code is needed, provide usable code.",
        "memory": "Use local memory when relevant. If memory is empty or irrelevant, say so briefly.",
        "review": "You are in review mode. Look for correctness, risks, missing cases, and concrete improvements.",
        "ops": "You are in operations mode. Prefer terminal-safe commands, verification steps, and rollback notes.",
    }
    return guidance.get(intent, guidance["chat"])


async def _memory_context(
    client: MemoryApiClient,
    message: str,
    use_memory: bool,
    limit: int,
) -> dict[str, Any]:
    metadata: dict[str, Any] = {
        "enabled": use_memory,
        "status": "disabled",
        "results_count": 0,
    }
    if not use_memory:
        return {"metadata": metadata, "context": None}

    try:
        response = await client.search(query=message, limit=limit)
    except MemoryApiUnavailable:
        metadata["status"] = "unavailable"
        return {"metadata": metadata, "context": None}

    results = response.get("results")
    if not isinstance(results, list):
        results = []
    selected = results[:limit]

    metadata.update(
        {
            "status": "ok" if selected else "empty",
            "results_count": len(selected),
            "collection_name": response.get("collection_name"),
            "embedding_backend": response.get("embedding_backend"),
            "embedding_dim": response.get("embedding_dim"),
        }
    )

    if not selected:
        return {"metadata": metadata, "context": None}

    lines = [
        "Use the following local memory only if relevant. If it is not relevant, ignore it.",
    ]
    for index, item in enumerate(selected, start=1):
        if not isinstance(item, dict):
            continue
        text = str(item.get("text") or "").strip()
        if not text:
            continue
        source = item.get("source") or "unknown"
        score = item.get("score")
        score_text = f", score={score:.4f}" if isinstance(score, (int, float)) else ""
        lines.append(f"{index}. source={source}{score_text}: {text}")

    if len(lines) == 1:
        metadata["status"] = "empty"
        metadata["results_count"] = 0
        return {"metadata": metadata, "context": None}

    return {"metadata": metadata, "context": "\n".join(lines)}
