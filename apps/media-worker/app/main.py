from fastapi import FastAPI

from app.config import get_settings
from app.image_jobs import process_real_image
from app.processor import process_dry_run
from app.schemas import WorkerProcessRequest

app = FastAPI(title="MoE Media Worker", version="0.1.0")


@app.get("/health")
def health() -> dict:
    settings = get_settings()
    return {
        "status": "ok",
        "service": settings.service_name,
        "dry_run_only": not settings.real_generation_enabled,
        "real_generation_enabled": settings.real_generation_enabled,
    }


@app.post("/worker/process")
def worker_process(request: WorkerProcessRequest) -> dict:
    if request.mode not in {"dry_run", "real"}:
        return {
            "status": "rejected",
            "mode": request.mode,
            "reason": "mode must be dry_run or real",
        }
    settings = get_settings()
    if request.mode == "real":
        result = process_real_image(settings, request.job_id)
        if result is None:
            return {"status": "not_found", "job_id": request.job_id}
        return result
    result = process_dry_run(settings, request.job_id)
    if result is None:
        return {"status": "not_found", "job_id": request.job_id}
    _, report_path = result
    return {
        "status": "ok",
        "job_id": request.job_id,
        "report_path": str(report_path),
    }
