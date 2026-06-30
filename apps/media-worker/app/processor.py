import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.config import Settings


def process_dry_run(settings: Settings, job_id: str) -> tuple[dict[str, Any], Path] | None:
    job_path = safe_job_path(settings, job_id)
    if job_path is None or not job_path.exists():
        return None
    job = json.loads(job_path.read_text(encoding="utf-8"))
    job["state"] = "processed_dry_run"
    job["updated_at"] = datetime.now(UTC).isoformat()
    job_path.write_text(json.dumps(job, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    reports_dir = Path(settings.reports_dir).expanduser().resolve()
    reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = (
        reports_dir / f"media-worker-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{job_id}.json"
    ).resolve()
    if not report_path.is_relative_to(reports_dir):
        raise ValueError("report path escaped MEDIA_REPORTS_DIR")
    report = {
        "service": settings.service_name,
        "report_type": "media-worker-dry-run",
        "created_at": datetime.now(UTC).isoformat(),
        "job": job,
        "outputs_created": [],
        "safety": {
            "dry_run_only": True,
            "media_generated": False,
            "comfyui_called": False,
            "blender_called": False,
            "model_runtime_called": False,
            "shell_executed": False,
        },
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return job, report_path


def safe_job_path(settings: Settings, job_id: str) -> Path | None:
    if "/" in job_id or "\\" in job_id or job_id.startswith("."):
        return None
    jobs_dir = Path(settings.jobs_dir).expanduser().resolve()
    path = (jobs_dir / f"{job_id}.json").resolve()
    if not path.is_relative_to(jobs_dir):
        return None
    return path
