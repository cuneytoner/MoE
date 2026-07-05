from typing import Any

from app.config import Settings
from app.services.runtime_profile_compatibility_matrix import (
    build_runtime_profile_compatibility_matrix,
)


RECOMMENDATION_TARGETS = {
    "default": "qwen-coder-14b-fast",
    "review": "qwen-coder-32b-main",
    "fallback": "deepseek-coder-lite",
}


def _profile_by_target(profiles: list[dict[str, Any]], target: str) -> dict[str, Any] | None:
    for profile in profiles:
        if profile.get("model_target") == target:
            return profile
    return None


def _recommendation(
    role: str,
    profile: dict[str, Any] | None,
) -> dict[str, Any]:
    if not profile:
        return {
            "model_target": "",
            "model_config_id": None,
            "compatibility": "unknown",
            "risk_level": "unknown",
            "reason": f"No profile data is available for {role}.",
            "warnings": [f"Missing {role} runtime profile data."],
        }

    target = str(profile.get("model_target") or "")
    compatibility = str(profile.get("compatibility") or "unknown")
    risk_level = str(profile.get("risk_level") or "unknown")
    warnings = list(profile.get("warnings") or [])
    if role == "default":
        reason = "Recommended default coding profile when compatible on PC-1."
    elif role == "review":
        reason = "Recommended review profile for heavier work, with human review of risk."
        if compatibility != "unknown" and risk_level == "high":
            warnings.append("Review profile is high risk on the static PC-1 hardware profile.")
    else:
        reason = "Recommended fallback profile when the default runtime is not desired."

    return {
        "model_target": target,
        "model_config_id": profile.get("model_config_id"),
        "compatibility": compatibility,
        "risk_level": risk_level,
        "reason": reason,
        "warnings": warnings,
    }


def _summary_warnings(recommendations: dict[str, dict[str, Any]]) -> list[str]:
    warnings: list[str] = []
    for role, recommendation in recommendations.items():
        if not recommendation.get("model_target"):
            warnings.append(f"{role} recommendation is missing a model target.")
        if recommendation.get("compatibility") == "unknown":
            warnings.append(f"{role} recommendation has unknown compatibility.")
        if recommendation.get("risk_level") in {"high", "unknown"}:
            warnings.append(f"{role} recommendation requires human review.")
    return warnings


async def build_runtime_profile_recommendation_summary(
    settings: Settings,
) -> dict[str, Any]:
    matrix = await build_runtime_profile_compatibility_matrix(settings)
    profiles = [
        profile
        for profile in matrix.get("profiles", [])
        if isinstance(profile, dict)
    ]
    recommendations = {
        role: _recommendation(role, _profile_by_target(profiles, target))
        for role, target in RECOMMENDATION_TARGETS.items()
    }
    warnings = _summary_warnings(recommendations)

    return {
        "status": "review_required" if warnings else "ok",
        "service": "gateway-runtime-profile-recommendation-summary",
        "read_only": True,
        "documentation_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
        "runbook": "docs/gateway-runtime-switch-runbook.md",
        "hardware_profile": matrix.get("hardware_profile", {}),
        "recommendations": recommendations,
        "profiles": profiles,
        "warnings": warnings,
        "next_steps": [
            "Review the recommended profile and compatibility notes before any manual runtime change.",
            "Use the Gateway runtime switch runbook for human-operated runtime changes.",
            "Keep Continue pointed at Gateway-Auto after any manual runtime review.",
        ],
    }
