from pathlib import Path
from typing import Any

from app.clients.model_runtime import ModelRuntimeClient
from app.config import Settings
from app.services.model_mapping import get_model_mapping


def _looks_like_local_path(value: str | None) -> bool:
    if not value:
        return False
    return value.startswith("/") or value.startswith("~/")


def _profile_readiness(
    runtime_model_id: str | None,
    file_exists: bool | None,
) -> str:
    if not runtime_model_id:
        return "review_required"
    if file_exists is True:
        return "ready"
    if file_exists is False:
        return "missing_file"
    return "unknown"


def _profile_warnings(
    runtime_model_id: str | None,
    file_exists: bool | None,
    readiness: str,
) -> list[str]:
    warnings: list[str] = []
    if not runtime_model_id:
        warnings.append("No runtime model id is configured for this profile.")
    if file_exists is False:
        warnings.append("Configured local model file is missing.")
    if readiness == "unknown":
        warnings.append("Runtime model id is not a local file path, so file readiness is unknown.")
    return warnings


async def build_runtime_profile_preflight(settings: Settings) -> dict[str, Any]:
    mapping = get_model_mapping(settings.model_routing_config)
    runtime_status = await ModelRuntimeClient(settings.model_runtime_url).status()
    profiles: list[dict[str, Any]] = []

    for model_target, target in sorted(mapping.model_targets.items()):
        runtime_model_id_value = target.get("runtime_model_id")
        runtime_model_id = str(runtime_model_id_value) if runtime_model_id_value else None
        file_path = runtime_model_id if _looks_like_local_path(runtime_model_id) else None
        file_exists = Path(file_path).expanduser().exists() if file_path else None
        mapping_status = "mapped" if runtime_model_id else "review_required"
        readiness = _profile_readiness(runtime_model_id, file_exists)

        profiles.append(
            {
                "model_target": model_target,
                "runtime_model_id": runtime_model_id,
                "mapping_status": mapping_status,
                "file_path": file_path,
                "file_exists": file_exists,
                "readiness": readiness,
                "warnings": _profile_warnings(runtime_model_id, file_exists, readiness),
            }
        )

    status = "ok"
    if any(profile["readiness"] != "ready" for profile in profiles):
        status = "review_required"

    return {
        "status": status,
        "service": "gateway-runtime-profile-preflight",
        "read_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "model_runtime_url": settings.model_runtime_public_url,
        "active_model": runtime_status["current_model"],
        "profiles": profiles,
    }
