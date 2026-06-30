import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from app.config import Settings


def build_report(
    settings: Settings,
    *,
    mode: str,
    events: list[dict[str, Any]],
    summary: dict[str, Any],
) -> dict[str, Any]:
    observations = [
        "Feedback report is running in dry_run mode.",
        "Feedback events are runtime-only JSONL records.",
    ]
    recommendations = [
        "Review feedback patterns manually before changing prompts, routing, configs, or models.",
    ]
    if summary.get("failure", 0):
        recommendations.append("Review common failure reasons before planning follow-up work.")
    if summary.get("total", 0) == 0:
        observations.append("No feedback events were available for this report.")

    return {
        "service": settings.service_name,
        "mode": mode,
        "created_at": datetime.now(UTC).isoformat(),
        "events_file": settings.events_file,
        "events": events,
        "summary": summary,
        "observations": observations,
        "recommendations": recommendations,
        "safety": {
            "source_modified": False,
            "router_modified": False,
            "model_mapping_modified": False,
            "shell_executed": False,
        },
    }


def write_report(settings: Settings, report: dict[str, Any]) -> Path:
    reports_dir = Path(settings.reports_dir).expanduser()
    reports_dir.mkdir(parents=True, exist_ok=True)
    resolved_reports_dir = reports_dir.resolve()
    filename = f"feedback-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{uuid4().hex[:8]}.json"
    report_path = (resolved_reports_dir / filename).resolve()

    if not report_path.is_relative_to(resolved_reports_dir):
        raise ValueError("report path escaped configured reports directory")

    report["report_path"] = str(report_path)
    report_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return report_path


def latest_report_metadata(settings: Settings) -> dict[str, Any] | None:
    reports_dir = Path(settings.reports_dir).expanduser()
    if not reports_dir.exists():
        return None

    reports = sorted(
        reports_dir.glob("feedback-*.json"),
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
        "summary": data.get("summary", {}),
    }
