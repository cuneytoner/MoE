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
    source_set: str,
    sources: list[dict[str, Any]],
) -> dict[str, Any]:
    processed = [source for source in sources if source.get("status") == "processed"]
    skipped = [source for source in sources if source.get("status") == "skipped"]
    observations = [
        "Research ingestion is running in dry_run mode.",
        "Only approved local markdown/text sources are processed.",
        "Remote URL fetching is disabled.",
    ]
    recommendations = [
        "Review skipped sources before enabling future ingestion gates.",
    ]

    if not processed:
        recommendations.append("No local sources were processed; verify source config and source mount.")
    if skipped:
        observations.append(f"{len(skipped)} source(s) were skipped by safety gates.")

    return {
        "service": settings.service_name,
        "mode": mode,
        "created_at": datetime.now(UTC).isoformat(),
        "source_set": source_set,
        "source_root": settings.source_root,
        "sources_config": settings.sources_config,
        "approved_sources_only": True,
        "remote_fetch_enabled": False,
        "sources": sources,
        "observations": observations,
        "recommendations": recommendations,
        "safety": {
            "remote_fetch_performed": False,
            "source_modified": False,
            "shell_executed": False,
        },
    }


def write_report(settings: Settings, report: dict[str, Any]) -> Path:
    reports_dir = Path(settings.reports_dir).expanduser()
    reports_dir.mkdir(parents=True, exist_ok=True)
    resolved_reports_dir = reports_dir.resolve()
    filename = f"research-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{uuid4().hex[:8]}.json"
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
        reports_dir.glob("research-*.json"),
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

    sources = data.get("sources", [])
    processed = [source for source in sources if source.get("status") == "processed"]
    skipped = [source for source in sources if source.get("status") == "skipped"]
    return {
        "status": "ok",
        "report_path": str(latest.resolve()),
        "created_at": data.get("created_at"),
        "mode": data.get("mode"),
        "source_set": data.get("source_set"),
        "summary": {
            "sources_loaded": len(sources),
            "sources_processed": len(processed),
            "sources_skipped": len(skipped),
            "findings_stored": data.get("summary", {}).get("findings_stored", False),
        },
    }
