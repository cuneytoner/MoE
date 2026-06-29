import time
from typing import Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.memory_api import MemoryApiClient, MemoryApiUnavailable
from app.clients.model_runtime import ModelRuntimeClient, ModelRuntimeUnavailable
from app.config import get_settings
from app.models.gateway import (
    GatewayChatRequest,
    GatewayChatResponse,
    GatewayCodeAskRequest,
    GatewayCodeAskResponse,
    GatewayCodeContextRequest,
    GatewayCodeContextResponse,
    GatewayCodeDiffSuggestRequest,
    GatewayCodeDiffSuggestResponse,
    GatewayCodePatchPlanRequest,
    GatewayCodePatchPlanResponse,
    GatewayHealthResponse,
    GatewayModelRoutingResponse,
    GatewayModelsResponse,
    GatewayRouteRequest,
    GatewayRouteResponse,
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
)
from app.services.model_mapping import ModelMapping, get_model_mapping
from app.services.patch_planner import (
    diff_suggest_system_prompt,
    parse_diff_suggestion,
    parse_patch_plan,
    patch_plan_system_prompt,
)
from app.services.repo_agent import RepoAgentService
from app.services.router import RouteDecision, route_message
from app.services.tool_executor import execute_tool
from app.services.tool_planner import tool_catalog
from app.services.workspace import WorkspaceService

app = FastAPI(title="MoE Gateway API", version="0.1.0")


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
    intent, target = _switch_plan_target(request, mapping)
    target_runtime_id = mapping.runtime_id(target)
    current_model = status["current_model"]
    switch_required = current_model != target_runtime_id
    manual_command = f"make model-switch MODEL={target}"
    reason = (
        "Target model differs from current runtime model"
        if switch_required
        else "Target model is already loaded"
    )
    if not status["runtime_available"]:
        switch_required = True
        reason = "Model runtime is unavailable"

    return GatewayRuntimeSwitchPlanResponse(
        status="ok",
        intent=intent,
        target=target,
        target_runtime_id=target_runtime_id,
        current_runtime_model=current_model,
        switch_required=switch_required,
        manual_command=manual_command,
        reason=reason,
    )


@app.post("/gateway/chat", response_model=GatewayChatResponse)
async def chat(request: GatewayChatRequest) -> GatewayChatResponse:
    return await _gateway_chat(request)


@app.post("/v1/chat/completions", response_model=OpenAIChatCompletionResponse)
async def openai_chat_completions(
    request: OpenAIChatCompletionRequest,
) -> OpenAIChatCompletionResponse:
    if request.stream:
        raise HTTPException(
            status_code=400,
            detail="streaming is not supported by the Gateway OpenAI compatibility adapter yet",
        )

    gateway_request = _openai_to_gateway_chat_request(request)
    response = await _gateway_chat(gateway_request)

    return OpenAIChatCompletionResponse(
        id=f"chatcmpl-local-{uuid4().hex}",
        object="chat.completion",
        created=int(time.time()),
        model=request.model,
        choices=[
            OpenAIChatCompletionChoice(
                index=0,
                message=OpenAIChatMessage(
                    role="assistant",
                    content=response.content,
                ),
                finish_reason="stop",
            )
        ],
        usage=OpenAIChatCompletionUsage(),
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
