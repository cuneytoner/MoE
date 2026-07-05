from typing import Any

from app.config import Settings
from app.services.runtime_profile_recommendation_summary import (
    build_runtime_profile_recommendation_summary,
)


SOURCE_ENDPOINT = "/gateway/runtime/profile-recommendation-summary"


async def build_compact_runtime_profile_summary(settings: Settings) -> dict[str, Any]:
    summary = await build_runtime_profile_recommendation_summary(settings)
    return {
        "status": summary.get("status"),
        "hardware_profile": summary.get("hardware_profile"),
        "recommendations": summary.get("recommendations"),
        "warnings": summary.get("warnings", []),
        "next_steps": summary.get("next_steps", []),
        "source_endpoint": SOURCE_ENDPOINT,
        "read_only": True,
        "documentation_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
    }


async def build_runtime_profile_dashboard_summary(settings: Settings) -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "gateway-runtime-profile-dashboard-summary",
        "read_only": True,
        "documentation_only": True,
        "runtime_switch_supported": False,
        "runtime_switch_attempted": False,
        "auto_execution_supported": False,
        "source_endpoint": SOURCE_ENDPOINT,
        "summary": await build_compact_runtime_profile_summary(settings),
    }
