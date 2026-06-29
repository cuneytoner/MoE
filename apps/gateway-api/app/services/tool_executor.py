from typing import Any

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.memory_api import MemoryApiClient
from app.clients.model_runtime import ModelRuntimeClient
from app.config import Settings
from app.services.model_mapping import get_model_mapping
from app.services.tool_planner import tool_catalog

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
            "status": "rejected",
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
