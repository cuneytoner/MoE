import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.comfyui_client import build_flux_workflow, check_health, discover_and_copy_outputs, submit_prompt
from app.config import Settings
from app.processor import safe_job_path


def process_real_image(settings: Settings, job_id: str) -> dict[str, Any] | None:
    job_path = safe_job_path(settings, job_id)
    if job_path is None or not job_path.exists():
        return None
    job = json.loads(job_path.read_text(encoding="utf-8"))
    if job.get("job_type") != "image" or job.get("mode") != "real":
        return {"status": "rejected", "reason": "only real image jobs are supported"}
    if not settings.real_generation_enabled:
        return {"status": "rejected", "reason": "MEDIA_REAL_GENERATION_ENABLED must be true"}
    healthy, health_error = check_health(settings.comfyui_url)
    if not healthy:
        return {
            "status": "rejected",
            "reason": f"ComfyUI health check failed: {health_error}",
        }

    timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
    filename_prefix = f"moe_media_{job_id}_{timestamp}"
    marker = Path("/tmp") / f"moe-media-{job_id}-{timestamp}.marker"
    marker.write_text(timestamp, encoding="utf-8")

    workflow = build_flux_workflow(job, filename_prefix)
    try:
        response = submit_prompt(settings.comfyui_url, workflow)
    except RuntimeError as exc:
        return {"status": "rejected", "reason": str(exc)}
    output_dir = Path(settings.output_root).expanduser().resolve() / "images" / job_id
    outputs = discover_and_copy_outputs(
        [
            Path(settings.comfyui_output_dir).expanduser().resolve(),
            Path(settings.output_root).expanduser().resolve() / "images",
        ],
        output_dir,
        marker,
    )

    if not outputs:
        return {
            "status": "rejected",
            "reason": "no ComfyUI output image detected",
            "prompt_id": response.get("prompt_id"),
        }

    job["state"] = "processed_real"
    job["updated_at"] = datetime.now(UTC).isoformat()
    job["outputs"] = outputs
    job["comfyui"] = {"prompt_id": response.get("prompt_id"), "filename_prefix": filename_prefix}
    job_path.write_text(json.dumps(job, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    reports_dir = Path(settings.reports_dir).expanduser().resolve()
    reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = reports_dir / f"media-worker-real-{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}-{job_id}.json"
    report = {
        "service": settings.service_name,
        "report_type": "media-worker-real-image",
        "created_at": datetime.now(UTC).isoformat(),
        "job": job,
        "outputs_created": outputs,
        "safety": {
            "dry_run_only": False,
            "media_generated": True,
            "comfyui_called": True,
            "shell_executed": False,
            "outputs_under_runtime": True,
        },
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return {"status": "ok", "job_id": job_id, "outputs": outputs, "report_path": str(report_path)}
