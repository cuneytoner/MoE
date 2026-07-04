from pathlib import Path
from typing import Any

import yaml

from app.config import Settings
from app.services.model_mapping import get_model_mapping
from app.services.runtime_profile_catalog_defaults import DEFAULT_MODELS, DEFAULT_RUNTIME


MODEL_SETTING_KEYS = (
    "context",
    "gpu_layers",
    "threads",
    "batch_size",
    "ubatch_size",
    "cache_type_k",
    "cache_type_v",
    "flash_attention",
)


def _config_dirs(settings: Settings) -> list[Path]:
    candidates: list[Path] = []
    configured = Path(settings.model_routing_config)
    candidates.append(configured.expanduser().resolve().parent)

    for parent in Path(__file__).resolve().parents:
        repo_configs = parent / "configs"
        if repo_configs.exists():
            candidates.append(repo_configs)

    candidates.append(Path("/app/configs"))

    unique: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        key = str(candidate)
        if key not in seen:
            unique.append(candidate)
            seen.add(key)
    return unique


def _load_config_file(settings: Settings, file_name: str) -> dict[str, Any]:
    for config_dir in _config_dirs(settings):
        data = _load_yaml(config_dir / file_name)
        if data:
            return data
    return {}


def _load_yaml(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle) or {}
    except FileNotFoundError:
        return {}
    if not isinstance(data, dict):
        return {}
    return data


def _model_entries(settings: Settings) -> list[dict[str, Any]]:
    data = _load_config_file(settings, "models.yaml")
    models = data.get("models")
    candidates: list[dict[str, Any]] = []
    if isinstance(models, list):
        candidates.extend(model for model in models if isinstance(model, dict))
    candidates.extend(model.copy() for model in DEFAULT_MODELS)
    return _dedupe_model_entries(candidates)


def _runtime_defaults(settings: Settings) -> dict[str, Any]:
    data = _load_config_file(settings, "runtime.yaml")
    runtime = data.get("model_runtime")
    if not isinstance(runtime, dict):
        return DEFAULT_RUNTIME.copy()
    return {**DEFAULT_RUNTIME, **runtime}


def _dedupe_model_entries(models: list[dict[str, Any]]) -> list[dict[str, Any]]:
    unique: list[dict[str, Any]] = []
    seen: set[str] = set()
    for model in models:
        model_id = str(model.get("id") or "")
        model_path = str(model.get("path") or "")
        key = model_id or model_path
        if key and key in seen:
            continue
        if key:
            seen.add(key)
        unique.append(model)
    return unique


def _match_model_config(
    model_target: str,
    runtime_model_id: str | None,
    models: list[dict[str, Any]],
) -> dict[str, Any] | None:
    if runtime_model_id:
        for model in models:
            if str(model.get("path") or "") == runtime_model_id:
                return model
    for model in models:
        if str(model.get("id") or "") == model_target:
            return model
    for model in DEFAULT_MODELS:
        if str(model.get("id") or "") == model_target:
            return model
    normalized_target = model_target.lower().replace("-", " ")
    for model in models:
        name = str(model.get("name") or "").lower()
        if normalized_target and normalized_target in name:
            return model
    for model in DEFAULT_MODELS:
        name = str(model.get("name") or "").lower()
        if normalized_target and normalized_target in name:
            return model
    return None


def _readiness_hint(
    runtime_model_id: str | None,
    model_config: dict[str, Any] | None,
) -> str:
    if model_config:
        return "review model settings before any manual runtime change"
    if runtime_model_id:
        return "review required because routing target has no matching model settings"
    return "review required because routing target has no runtime model id"


def _warnings(
    runtime_model_id: str | None,
    model_config: dict[str, Any] | None,
    runtime_defaults: dict[str, Any],
) -> list[str]:
    warnings: list[str] = []
    if not runtime_model_id:
        warnings.append("No runtime model id is configured for this routing profile.")
    if model_config is None:
        warnings.append("No matching model settings entry was found in configs/models.yaml.")
    if not runtime_defaults:
        warnings.append("Runtime defaults were not found in configs/runtime.yaml.")
    return warnings


def _setting(model_config: dict[str, Any] | None, key: str) -> Any:
    if not model_config:
        return None
    return model_config.get(key)


def _has_required_catalog_fields(profile: dict[str, Any]) -> bool:
    return bool(profile.get("model_config_id")) and all(
        profile.get(key) is not None for key in MODEL_SETTING_KEYS
    )


async def build_runtime_profile_run_catalog(settings: Settings) -> dict[str, Any]:
    mapping = get_model_mapping(settings.model_routing_config)
    models = _model_entries(settings)
    runtime_defaults = _runtime_defaults(settings)
    profiles: list[dict[str, Any]] = []

    for model_target, target in sorted(mapping.model_targets.items()):
        runtime_model_id_value = target.get("runtime_model_id")
        runtime_model_id = str(runtime_model_id_value) if runtime_model_id_value else None
        model_config = _match_model_config(model_target, runtime_model_id, models)
        model_path = None
        if model_config:
            model_path_value = model_config.get("path")
            model_path = str(model_path_value) if model_path_value else runtime_model_id
        else:
            model_path = runtime_model_id

        warnings = _warnings(runtime_model_id, model_config, runtime_defaults)
        profile = {
            "model_target": model_target,
            "runtime_model_id": runtime_model_id,
            "model_config_id": str(model_config.get("id")) if model_config else None,
            "model_path": model_path,
            "readiness_hint": _readiness_hint(runtime_model_id, model_config),
            "warnings": warnings,
            "manual_run_reference": (
                "Use the documented host runtime scripts manually after reviewing "
                "the Gateway runtime switch runbook."
            ),
        }
        for key in MODEL_SETTING_KEYS:
            profile[key] = _setting(model_config, key)
        profiles.append(profile)

    status = (
        "review_required"
        if any(not _has_required_catalog_fields(profile) for profile in profiles)
        else "ok"
    )

    return {
        "status": status,
        "service": "gateway-runtime-profile-run-catalog",
        "read_only": True,
        "documentation_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
        "runbook": "docs/gateway-runtime-switch-runbook.md",
        "profiles": profiles,
    }
