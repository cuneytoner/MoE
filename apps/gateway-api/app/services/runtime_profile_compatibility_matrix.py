from typing import Any, Literal

from app.config import Settings
from app.services.runtime_profile_run_catalog import build_runtime_profile_run_catalog


HARDWARE_PROFILE = {
    "name": "pc1-rtx-5060-ti-16gb",
    "gpu": "NVIDIA RTX 5060 Ti",
    "vram_gb": 16,
    "ram_gb": 32,
    "cpu": "AMD Ryzen 7 7800X3D",
}


Compatibility = Literal["compatible", "borderline", "review_required", "unknown"]
RiskLevel = Literal["low", "medium", "high", "unknown"]
Pressure = Literal["low", "medium", "high", "unknown"]


def _int_value(value: Any) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _missing_settings(profile: dict[str, Any]) -> list[str]:
    required = [
        "model_config_id",
        "runtime_model_id",
        "context",
        "gpu_layers",
        "batch_size",
        "ubatch_size",
    ]
    return [key for key in required if profile.get(key) is None]


def _model_class(profile: dict[str, Any]) -> str:
    text = " ".join(
        str(profile.get(key) or "")
        for key in ("model_target", "model_config_id", "runtime_model_id")
    ).lower()
    if "32b" in text or "30b" in text:
        return "large"
    if "14b" in text:
        return "medium"
    if "deepseek" in text or "lite" in text:
        return "lite"
    return "unknown"


def _evaluate_profile(profile: dict[str, Any]) -> dict[str, Any]:
    missing = _missing_settings(profile)
    notes: list[str] = [
        "Advisory static compatibility estimate for PC-1 hardware assumptions.",
    ]
    warnings = list(profile.get("warnings") or [])
    context = _int_value(profile.get("context"))
    gpu_layers = _int_value(profile.get("gpu_layers"))
    model_class = _model_class(profile)

    if missing:
        warnings.append(f"Missing catalog settings: {', '.join(missing)}.")
        return {
            "compatibility": "unknown",
            "risk_level": "unknown",
            "estimated_vram_pressure": "unknown",
            "notes": notes,
            "warnings": warnings,
        }

    compatibility: Compatibility = "compatible"
    risk_level: RiskLevel = "medium"
    pressure: Pressure = "medium"

    if model_class == "medium":
        compatibility = "compatible"
        risk_level = "low" if context and context < 16384 else "medium"
        pressure = "low" if context and context < 16384 else "medium"
        notes.append("14B coding profile is expected to fit the 16 GB VRAM class.")
    elif model_class == "lite":
        compatibility = "compatible"
        risk_level = "medium"
        pressure = "medium"
        notes.append("Lite fallback profile is expected to be usable on 16 GB VRAM.")
        if gpu_layers is not None and gpu_layers <= 48:
            compatibility = "borderline" if context and context >= 32768 else "compatible"
            notes.append("Moderate GPU layer count keeps this profile in a safer range.")
    elif model_class == "large":
        compatibility = "borderline"
        risk_level = "high"
        pressure = "high"
        notes.append("30B/32B class profile needs human review on 16 GB VRAM.")
        if gpu_layers is not None and gpu_layers >= 900:
            compatibility = "review_required"
            warnings.append("Full GPU offload may not fit on 16 GB VRAM for this profile.")
    else:
        compatibility = "unknown"
        risk_level = "unknown"
        pressure = "unknown"
        warnings.append("Unknown model size class; review compatibility manually.")

    if context is not None and context >= 16384:
        warnings.append("Large context size may increase VRAM pressure.")
        if pressure == "low":
            pressure = "medium"
        if risk_level == "low":
            risk_level = "medium"

    return {
        "compatibility": compatibility,
        "risk_level": risk_level,
        "estimated_vram_pressure": pressure,
        "notes": notes,
        "warnings": warnings,
    }


async def build_runtime_profile_compatibility_matrix(
    settings: Settings,
) -> dict[str, Any]:
    catalog = await build_runtime_profile_run_catalog(settings)
    profiles: list[dict[str, Any]] = []

    for profile in catalog.get("profiles", []):
        if not isinstance(profile, dict):
            continue
        evaluation = _evaluate_profile(profile)
        profiles.append(
            {
                "model_target": profile.get("model_target"),
                "model_config_id": profile.get("model_config_id"),
                "runtime_model_id": profile.get("runtime_model_id"),
                "context": profile.get("context"),
                "gpu_layers": profile.get("gpu_layers"),
                "batch_size": profile.get("batch_size"),
                "ubatch_size": profile.get("ubatch_size"),
                **evaluation,
            }
        )

    status = (
        "review_required"
        if any(
            profile["compatibility"] in {"review_required", "unknown"}
            or profile["risk_level"] in {"high", "unknown"}
            for profile in profiles
        )
        else "ok"
    )

    return {
        "status": status,
        "service": "gateway-runtime-profile-compatibility-matrix",
        "read_only": True,
        "documentation_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
        "hardware_profile": HARDWARE_PROFILE.copy(),
        "profiles": profiles,
    }
