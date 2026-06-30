from fastapi import FastAPI
import json
import urllib.error
import urllib.request

from app.config import get_settings
from app.schemas import (
    DryRunProcessResponse,
    HealthResponse,
    MediaJobRequest,
    MediaJobResponse,
    MediaJobSummary,
)
from app.store import create_job, latest_report_metadata, load_job, mark_processed_dry_run

app = FastAPI(title="MoE Media API", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        dry_run_only=not settings.real_generation_enabled,
        real_generation_enabled=settings.real_generation_enabled,
        media_root=settings.media_root,
        jobs_dir=settings.jobs_dir,
        outputs_dir=settings.outputs_dir,
    )


@app.post("/media/jobs", response_model=MediaJobResponse, response_model_exclude_none=True)
def media_jobs(request: MediaJobRequest) -> MediaJobResponse:
    if request.mode not in {"dry_run", "real"}:
        return MediaJobResponse(status="rejected", reason="mode must be dry_run or real")
    if request.mode == "real" and not get_settings().real_generation_enabled:
        return MediaJobResponse(
            status="rejected",
            reason="MEDIA_REAL_GENERATION_ENABLED must be true for real generation",
        )
    settings = get_settings()
    job = create_job(settings, request)
    return MediaJobResponse(
        status="ok",
        job=MediaJobSummary(
            job_id=job["job_id"],
            job_type=job["job_type"],
            mode=job["mode"],
            state=job["state"],
            job_path=job["job_path"],
        ),
    )


@app.get("/media/jobs/{job_id}")
def media_job(job_id: str) -> dict:
    settings = get_settings()
    job = load_job(settings, job_id)
    if job is None:
        return {"status": "not_found", "job_id": job_id}
    return {"status": "ok", "job": job}


@app.post("/media/jobs/{job_id}/dry-run-process", response_model=DryRunProcessResponse)
def media_job_dry_run_process(job_id: str) -> DryRunProcessResponse:
    settings = get_settings()
    result = mark_processed_dry_run(settings, job_id)
    if result is None:
        return DryRunProcessResponse(status="not_found", job_id=job_id)
    _, report_path = result
    return DryRunProcessResponse(
        status="ok",
        job_id=job_id,
        report_path=str(report_path),
    )


@app.post("/media/jobs/{job_id}/process", response_model=DryRunProcessResponse)
def media_job_process(job_id: str) -> DryRunProcessResponse:
    settings = get_settings()
    job = load_job(settings, job_id)
    if job is None:
        return DryRunProcessResponse(status="not_found", job_id=job_id)
    if job.get("mode") == "dry_run":
        result = mark_processed_dry_run(settings, job_id)
        if result is None:
            return DryRunProcessResponse(status="not_found", job_id=job_id)
        _, report_path = result
        return DryRunProcessResponse(status="ok", job_id=job_id, report_path=str(report_path))
    if job.get("mode") != "real":
        return DryRunProcessResponse(status="rejected", job_id=job_id, reason="unsupported job mode")
    if not settings.real_generation_enabled:
        return DryRunProcessResponse(
            status="rejected",
            job_id=job_id,
            reason="MEDIA_REAL_GENERATION_ENABLED must be true for real generation",
        )
    payload = json.dumps({"job_id": job_id, "mode": "real"}).encode("utf-8")
    request = urllib.request.Request(
        f"{settings.media_worker_url.rstrip('/')}/worker/process",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
        attempted_url = f"{settings.media_worker_url.rstrip('/')}/worker/process"
        return DryRunProcessResponse(
            status="rejected",
            job_id=job_id,
            reason=(
                "media worker request failed: "
                f"url={attempted_url} exception={exc.__class__.__name__}"
            ),
        )
    if data.get("status") != "ok":
        return DryRunProcessResponse(
            status="rejected",
            job_id=job_id,
            reason=data.get("reason", "media worker rejected job"),
        )
    return DryRunProcessResponse(
        status="ok",
        job_id=job_id,
        report_path=data.get("report_path"),
        outputs=data.get("outputs", []),
    )


@app.get("/media/latest-report")
def media_latest_report() -> dict:
    settings = get_settings()
    latest = latest_report_metadata(settings)
    if latest is None:
        return {"status": "empty"}
    return latest
