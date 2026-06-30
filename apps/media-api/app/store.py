import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from app.config import Settings
from app.image import image_dry_run_details


def create_job(settings: Settings, request: Any) -> dict[str, Any]:
    jobs_dir = _safe_dir(settings.jobs_dir)
    jobs_dir.mkdir(parents=True, exist_ok=True)
    job_id = f"media-{uuid4().hex[:12]}"
    job_path = (jobs_dir / f"{job_id}.json").resolve()
    if not job_path.is_relative_to(jobs_dir.resolve()):
        raise ValueError("job path escaped MEDIA_JOBS_DIR")

    job = {
        "job_id": job_id,
        "job_type": request.job_type,
        "mode": request.mode,
        "prompt": request.prompt,
        "negative_prompt": getattr(request, "negative_prompt", ""),
        "workflow": request.workflow,
        "metadata": request.metadata,
        "state": "queued",
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
        "dry_run_only": request.mode == "dry_run",
        "job_path": str(job_path),
    }
    job_path.write_text(json.dumps(job, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return job


def load_job(settings: Settings, job_id: str) -> dict[str, Any] | None:
    job_path = _job_path(settings, job_id)
    if job_path is None or not job_path.exists():
        return None
    return json.loads(job_path.read_text(encoding="utf-8"))


def mark_processed_dry_run(settings: Settings, job_id: str) -> tuple[dict[str, Any], Path] | None:
    job = load_job(settings, job_id)
    if job is None:
        return None

    job["state"] = "processed_dry_run"
    job["updated_at"] = datetime.now(UTC).isoformat()
    job_path = _job_path(settings, job_id)
    if job_path is None:
        return None
    job_path.write_text(json.dumps(job, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    report_path = write_report(settings, job)
    return job, report_path


def write_report(settings: Settings, job: dict[str, Any]) -> Path:
    reports_dir = _safe_dir(settings.reports_dir)
    reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = (
        reports_dir
        / f"media-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{job['job_id']}.json"
    ).resolve()
    if not report_path.is_relative_to(reports_dir.resolve()):
        raise ValueError("report path escaped MEDIA_REPORTS_DIR")

    report = {
        "service": settings.service_name,
        "report_type": "media-dry-run",
        "created_at": datetime.now(UTC).isoformat(),
        "job": job,
        "image": image_dry_run_details(job) if job.get("job_type") == "image" else None,
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
        reports_dir.glob("media-*.json"),
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
        "report_type": data.get("report_type"),
        "job_id": data.get("job", {}).get("job_id"),
        "job_type": data.get("job", {}).get("job_type"),
    }


def _job_path(settings: Settings, job_id: str) -> Path | None:
    if "/" in job_id or "\\" in job_id or job_id.startswith("."):
        return None
    jobs_dir = _safe_dir(settings.jobs_dir)
    path = (jobs_dir / f"{job_id}.json").resolve()
    if not path.is_relative_to(jobs_dir.resolve()):
        return None
    return path


def _safe_dir(path: str) -> Path:
    return Path(path).expanduser().resolve()
