from typing import Any

from app.config import Settings
from app.services.runtime_profile_recommendation_summary import (
    build_runtime_profile_recommendation_summary,
)


SOURCE_ENDPOINT = "/gateway/runtime/profile-recommendation-summary"
RUNBOOK = "docs/gateway-runtime-switch-runbook.md"


def _recommendation(summary: dict[str, Any], key: str) -> dict[str, Any]:
    recommendations = summary.get("recommendations")
    if not isinstance(recommendations, dict):
        return {}
    value = recommendations.get(key)
    return value if isinstance(value, dict) else {}


def _checklist_item(
    item_id: str,
    title: str,
    description: str,
    *,
    related_profile: str | None = None,
    risk_level: str | None = None,
) -> dict[str, Any]:
    item = {
        "id": item_id,
        "title": title,
        "status": "pending_manual_review",
        "description": description,
    }
    if related_profile:
        item["related_profile"] = related_profile
    if risk_level:
        item["risk_level"] = risk_level
    return item


async def build_runtime_profile_operator_checklist(settings: Settings) -> dict[str, Any]:
    summary = await build_runtime_profile_recommendation_summary(settings)
    default = _recommendation(summary, "default")
    review = _recommendation(summary, "review")
    fallback = _recommendation(summary, "fallback")
    warnings = list(summary.get("warnings") or [])

    checklist = [
        _checklist_item(
            "confirm-selected-profiles",
            "Confirm selected default, review, and fallback profiles",
            "Review the recommended profile choices before any human-operated runtime change.",
        ),
        _checklist_item(
            "confirm-model-file",
            "Confirm model file readiness",
            "Use the profile preflight result to confirm the selected model file is present or flagged for review.",
        ),
        _checklist_item(
            "confirm-compatibility-risk",
            "Confirm compatibility risk",
            "Review compatibility and risk labels before deciding whether a profile is appropriate.",
            related_profile=str(review.get("model_target") or ""),
            risk_level=str(review.get("risk_level") or ""),
        ),
        _checklist_item(
            "confirm-continue-gateway-auto",
            "Confirm Continue still points to Gateway-Auto",
            "Verify Continue remains configured for Gateway-Auto through the Gateway OpenAI-compatible endpoint.",
        ),
        _checklist_item(
            "confirm-active-runtime",
            "Confirm active runtime after any manual operator change",
            "After any human-operated runtime change, verify the active runtime profile through Gateway read-only status.",
        ),
        _checklist_item(
            "confirm-rollback-profile",
            "Confirm rollback profile is known",
            "Keep the previous known-good profile identified before making any human-operated runtime change.",
            related_profile=str(fallback.get("model_target") or ""),
            risk_level=str(fallback.get("risk_level") or ""),
        ),
        _checklist_item(
            "confirm-no-automatic-switch",
            "Confirm no automatic switch is expected",
            "Gateway remains advisory-only and does not change runtime models automatically.",
            related_profile=str(default.get("model_target") or ""),
            risk_level=str(default.get("risk_level") or ""),
        ),
    ]

    missing_profiles = [
        label
        for label, recommendation in (
            ("default", default),
            ("review", review),
            ("fallback", fallback),
        )
        if not recommendation.get("model_target")
    ]
    if missing_profiles:
        warnings.append(
            f"Missing recommendation data for: {', '.join(missing_profiles)}."
        )

    return {
        "status": "review_required" if warnings else "ok",
        "service": "gateway-runtime-profile-operator-checklist",
        "read_only": True,
        "documentation_only": True,
        "export_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
        "source_endpoint": SOURCE_ENDPOINT,
        "runbook": RUNBOOK,
        "checklist": checklist,
        "warnings": warnings,
        "rollback_guidance": (
            "If a manually selected profile is not healthy, return to the previous "
            "known-good profile using the manual runbook."
        ),
        "next_steps": [
            "Review every checklist item before any human-operated runtime change.",
            "Use Gateway read-only status endpoints to verify profile state after manual review.",
            "Keep Continue configured for Gateway-Auto unless a human operator intentionally changes local configuration.",
        ],
    }
