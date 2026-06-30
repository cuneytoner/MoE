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
    source_root_available: bool,
    gateway_reachable: bool,
    memory_api_reachable: bool,
    include_git_status: bool,
) -> dict[str, Any]:
    created_at = datetime.now(UTC).isoformat()
    observations = [
        "Nightly learning is running in dry_run mode.",
        "Source code modification, patch application, and shell execution are disabled.",
    ]
    recommendations = [
        "Review this report manually before turning any lesson into code or config changes.",
    ]

    if source_root_available:
        observations.append("Configured source root is available for read-only metadata checks.")
    else:
        recommendations.append("Verify the read-only source mount before scheduled worker activation.")

    if include_git_status:
        git_metadata = read_git_metadata(settings.source_root)
        if git_metadata["available"]:
            observations.append(f"Git metadata is readable at {git_metadata['head_ref']}.")
        else:
            observations.append("Git metadata was not readable from the configured source root.")
    else:
        git_metadata = {"available": False, "head_ref": None}

    if not gateway_reachable:
        recommendations.append("Gateway was not reachable during this dry run.")
    if not memory_api_reachable:
        recommendations.append("Memory API was not reachable during this dry run.")

    return {
        "service": settings.service_name,
        "mode": mode,
        "created_at": created_at,
        "source_root": settings.source_root,
        "checks": {
            "source_root_available": source_root_available,
            "gateway_reachable": gateway_reachable,
            "memory_api_reachable": memory_api_reachable,
        },
        "metadata": {
            "git": git_metadata,
        },
        "observations": observations,
        "recommendations": recommendations,
        "safety": {
            "source_modified": False,
            "patch_applied": False,
            "shell_executed": False,
        },
    }


def write_report(settings: Settings, report: dict[str, Any]) -> Path:
    reports_dir = Path(settings.reports_dir).expanduser()
    reports_dir.mkdir(parents=True, exist_ok=True)
    resolved_reports_dir = reports_dir.resolve()
    filename = f"nightly-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{uuid4().hex[:8]}.json"
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
        reports_dir.glob("nightly-*.json"),
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
        "summary": {
            "source_root_available": data.get("checks", {}).get("source_root_available"),
            "gateway_reachable": data.get("checks", {}).get("gateway_reachable"),
            "memory_api_reachable": data.get("checks", {}).get("memory_api_reachable"),
            "lessons_stored": data.get("summary", {}).get("lessons_stored", False),
        },
    }


def read_git_metadata(source_root: str) -> dict[str, Any]:
    root = Path(source_root)
    head = root / ".git" / "HEAD"
    if not head.exists() or not head.is_file():
        return {"available": False, "head_ref": None}

    try:
        value = head.read_text(encoding="utf-8").strip()
    except OSError:
        return {"available": False, "head_ref": None}

    return {"available": True, "head_ref": value[:200]}
