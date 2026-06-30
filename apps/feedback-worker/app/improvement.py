import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from app.config import Settings


def build_improvement_report(
    settings: Settings,
    *,
    mode: str,
    events: list[dict[str, Any]],
    include_router_recommendations: bool,
    include_model_mapping_recommendations: bool,
    include_prompt_recommendations: bool,
    include_test_recommendations: bool,
) -> dict[str, Any]:
    recommendations = {
        "router": [],
        "model_mapping": [],
        "prompts": [],
        "tests": [],
        "docs": [],
    }

    if not events:
        recommendations["docs"].append(
            recommendation(
                "Collect more feedback events",
                "No feedback events were available for deterministic analysis.",
                "Record feedback events after coding, ops, research, nightly, and media tasks before changing prompts or routing.",
            )
        )
    else:
        if include_router_recommendations:
            recommendations["router"].extend(router_recommendations(events))
        if include_model_mapping_recommendations:
            recommendations["model_mapping"].extend(model_mapping_recommendations(events))
        if include_prompt_recommendations:
            recommendations["prompts"].extend(prompt_recommendations(events))
        if include_test_recommendations:
            recommendations["tests"].extend(test_recommendations(events))
        recommendations["docs"].extend(docs_recommendations(events))

    summary = summarize_recommendations(events, recommendations)
    return {
        "service": settings.service_name,
        "report_type": "prompt-routing-improvement",
        "mode": mode,
        "created_at": datetime.now(UTC).isoformat(),
        "events_analyzed": len(events),
        "recommendations": recommendations,
        "summary": summary,
        "safety": {
            "source_modified": False,
            "router_modified": False,
            "prompt_modified": False,
            "patch_applied": False,
            "shell_executed": False,
            "apply_supported": False,
        },
    }


def write_improvement_report(settings: Settings, report: dict[str, Any]) -> Path:
    reports_dir = Path(settings.improvement_reports_dir).expanduser()
    reports_dir.mkdir(parents=True, exist_ok=True)
    resolved_reports_dir = reports_dir.resolve()
    filename = f"improvement-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{uuid4().hex[:8]}.json"
    report_path = (resolved_reports_dir / filename).resolve()

    if not report_path.is_relative_to(resolved_reports_dir):
        raise ValueError("improvement report path escaped configured reports directory")

    report["report_path"] = str(report_path)
    report_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return report_path


def latest_improvement_report_metadata(settings: Settings) -> dict[str, Any] | None:
    reports_dir = Path(settings.improvement_reports_dir).expanduser()
    if not reports_dir.exists():
        return None

    reports = sorted(
        reports_dir.glob("improvement-*.json"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not reports:
        return None

    latest = reports[0]
    try:
        data = json.loads(latest.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        data = {}

    return {
        "status": "ok",
        "report_path": str(latest.resolve()),
        "created_at": data.get("created_at"),
        "mode": data.get("mode"),
        "report_type": data.get("report_type"),
        "summary": data.get("summary", {}),
        "apply_supported": False,
    }


def router_recommendations(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    code_failures = [
        event
        for event in events
        if event.get("route_intent") == "code" and event.get("outcome") == "failure"
    ]
    if len(code_failures) >= 2:
        return [
            recommendation(
                "Review code intent routing examples",
                "Multiple failed events used route_intent=code.",
                "Review code intent keywords and add human-approved examples before changing router behavior.",
            )
        ]
    return []


def model_mapping_recommendations(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    mismatches = [
        event
        for event in events
        if event.get("model_target")
        and event.get("actual_model")
        and event.get("model_target") != event.get("actual_model")
    ]
    if mismatches:
        return [
            recommendation(
                "Review model target alignment",
                "Some feedback events show model_target differing from actual_model.",
                "Check model mapping docs and runtime switch workflow; do not change mappings automatically.",
            )
        ]
    return []


def prompt_recommendations(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    empty_files = [
        event
        for event in events
        if event.get("task_type") == "coding" and not event.get("selected_files")
    ]
    if empty_files:
        return [
            recommendation(
                "Improve workspace context prompting",
                "Some coding feedback events have no selected files.",
                "Review workspace search query generation and prompt guidance for file selection.",
            )
        ]
    return []


def test_recommendations(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    no_tests = [event for event in events if not event.get("tests_run")]
    timeout_failures = [
        event
        for event in events
        if "timeout" in (event.get("failure_reason") or "").lower()
        or "timeout" in (event.get("notes") or "").lower()
    ]
    recommendations: list[dict[str, Any]] = []
    if no_tests:
        recommendations.append(
            recommendation(
                "Record verification commands consistently",
                "Some feedback events do not include tests_run.",
                "Ensure final task summaries record exact verification commands.",
            )
        )
    if timeout_failures:
        recommendations.append(
            recommendation(
                "Add timeout troubleshooting coverage",
                "One or more failure notes mention timeout behavior.",
                "Add human-reviewed timeout troubleshooting docs or targeted tests.",
            )
        )
    return recommendations


def docs_recommendations(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    failures = [event for event in events if event.get("outcome") == "failure"]
    if failures:
        return [
            recommendation(
                "Review common failure documentation",
                "At least one feedback event ended in failure.",
                "Summarize repeated failure reasons in docs before changing operational behavior.",
            )
        ]
    return []


def summarize_recommendations(
    events: list[dict[str, Any]],
    recommendations: dict[str, list[dict[str, Any]]],
) -> dict[str, int]:
    router_count = len(recommendations["router"])
    model_count = len(recommendations["model_mapping"])
    prompt_count = len(recommendations["prompts"])
    test_count = len(recommendations["tests"])
    docs_count = len(recommendations["docs"])
    return {
        "events_analyzed": len(events),
        "recommendations_count": router_count
        + model_count
        + prompt_count
        + test_count
        + docs_count,
        "router_recommendations_count": router_count,
        "model_mapping_recommendations_count": model_count,
        "prompt_recommendations_count": prompt_count,
        "test_recommendations_count": test_count,
        "docs_recommendations_count": docs_count,
    }


def recommendation(title: str, reason: str, suggested_change: str) -> dict[str, Any]:
    return {
        "title": title,
        "reason": reason,
        "suggested_change": suggested_change,
        "apply_supported": False,
    }
