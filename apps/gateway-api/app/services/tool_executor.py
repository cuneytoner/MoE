from typing import Any

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.memory_api import MemoryApiClient
from app.clients.model_runtime import ModelRuntimeClient
from app.config import Settings
from app.services.model_mapping import get_model_mapping
from app.services.repo_agent import RepoAgentService
from app.services.tool_planner import tool_catalog
from app.services.workspace import WorkspaceService

REJECTED_REASON = "Tool is advisory only and cannot be executed by Gateway"


async def execute_tool(
    tool: str,
    arguments: dict[str, Any],
    settings: Settings,
) -> dict[str, Any]:
    catalog = tool_catalog()
    details = catalog.get(tool)
    if not details:
        return {
            "status": "error",
            "tool": tool,
            "reason": "Unknown tool",
        }

    if not details.get("executable") or not details.get("read_only"):
        return {
            "status": "rejected",
            "tool": tool,
            "reason": REJECTED_REASON,
        }

    result = await _execute_read_only_tool(tool, arguments, settings)
    return {
        "status": "ok",
        "tool": tool,
        "read_only": True,
        "result": result,
    }


async def _execute_read_only_tool(
    tool: str,
    arguments: dict[str, Any],
    settings: Settings,
) -> dict[str, Any]:
    if tool == "gateway_health_check":
        return {
            "service": settings.service_name,
            "status": "ok",
            "dependencies": await _dependency_statuses(settings),
        }

    if tool == "memory_health_check":
        return {
            "service": "memory-api",
            "status": await MemoryApiClient(settings.memory_api_url).check(),
        }

    if tool == "memory_deep_health_check":
        return await MemoryApiClient(settings.memory_api_url).deep_health()

    if tool == "embed_worker_health_check":
        return {
            "service": "embed-worker",
            "status": await EmbedWorkerClient(settings.embed_worker_url).check(),
        }

    if tool == "runtime_status_check":
        status = await ModelRuntimeClient(settings.model_runtime_url).status()
        return {
            "runtime_available": bool(status["runtime_available"]),
            "model_runtime_url": settings.model_runtime_public_url,
            "loaded_models": status["loaded_models"],
            "current_model": status["current_model"],
        }

    if tool == "model_routing_read":
        mapping = get_model_mapping(settings.model_routing_config)
        return mapping.safe_config()

    if tool == "tools_read":
        return {
            "tools": tool_catalog(),
            "auto_execution_enabled": False,
            "read_only_execution_enabled": True,
        }

    if tool == "workspace_status":
        return WorkspaceService(settings).status()

    if tool == "workspace_tree":
        return WorkspaceService(settings).tree(
            path=str(arguments.get("path") or "."),
            max_items=_optional_int(arguments.get("max_items")),
        )

    if tool == "workspace_file_read":
        return WorkspaceService(settings).file(path=str(arguments.get("path") or ""))

    if tool == "workspace_search":
        return WorkspaceService(settings).search(
            query=str(arguments.get("query") or ""),
            path=str(arguments.get("path") or "."),
            max_results=_optional_int(arguments.get("max_results")) or 20,
        )

    if tool == "workspace_context":
        paths = arguments.get("paths")
        if not isinstance(paths, list):
            paths = []
        return WorkspaceService(settings).context(
            task=str(arguments.get("task") or ""),
            paths=[str(path) for path in paths],
            max_chars=_optional_int(arguments.get("max_chars")) or 12000,
        )

    if tool == "code_context":
        paths = arguments.get("paths")
        if not isinstance(paths, list):
            paths = []
        return RepoAgentService(settings).build_context(
            task=str(arguments.get("task") or ""),
            query=_optional_str(arguments.get("query")),
            paths=[str(path) for path in paths],
            max_files=_optional_int(arguments.get("max_files")) or 8,
            max_chars=_optional_int(arguments.get("max_chars")) or 20000,
        )

    if tool == "code_ask":
        return {
            "status": "unavailable",
            "reason": "Use POST /gateway/code/ask so Gateway can attach route and memory metadata.",
        }

    return {
        "arguments": arguments,
        "message": "No read-only executor is registered for this tool.",
    }


async def _dependency_statuses(settings: Settings) -> dict[str, str]:
    return {
        "memory_api": await MemoryApiClient(settings.memory_api_url).check(),
        "embed_worker": await EmbedWorkerClient(settings.embed_worker_url).check(),
        "model_runtime": await ModelRuntimeClient(settings.model_runtime_url).check(),
    }


def _optional_int(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _optional_str(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None
