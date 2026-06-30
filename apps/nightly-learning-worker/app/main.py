from pathlib import Path
from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel

from app.clients import check_gateway, check_memory_api, store_lesson
from app.config import get_settings
from app.report import build_report, latest_report_metadata, write_report

app = FastAPI(title="MoE Nightly Learning Worker", version="0.1.0")


class HealthResponse(BaseModel):
    status: str
    service: str
    runtime_reports_dir: str
    source_root: str
    read_only: bool


class NightlyRunRequest(BaseModel):
    mode: str = "dry_run"
    include_git_status: bool = True
    include_gateway_summary: bool = True
    include_memory_summary: bool = True
    store_lessons: bool = False


class NightlyRunSummary(BaseModel):
    source_root_available: bool
    gateway_reachable: bool
    memory_api_reachable: bool
    lessons_stored: bool


class NightlyRunResponse(BaseModel):
    status: Literal["ok", "rejected"]
    mode: str
    report_path: str | None = None
    summary: NightlyRunSummary | None = None
    reason: str | None = None


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        runtime_reports_dir=settings.reports_dir,
        source_root=settings.source_root,
        read_only=True,
    )


@app.post("/nightly/run", response_model=NightlyRunResponse, response_model_exclude_none=True)
async def nightly_run(request: NightlyRunRequest) -> NightlyRunResponse:
    settings = get_settings()
    if request.mode != "dry_run":
        return NightlyRunResponse(
            status="rejected",
            mode=request.mode,
            reason="only dry_run mode is supported",
        )

    source_root_available = Path(settings.source_root).exists()
    gateway_reachable = False
    memory_api_reachable = False

    if request.include_gateway_summary:
        gateway_reachable = await check_gateway(settings)
    if request.include_memory_summary or request.store_lessons:
        memory_api_reachable = await check_memory_api(settings)

    report = build_report(
        settings,
        mode=request.mode,
        source_root_available=source_root_available,
        gateway_reachable=gateway_reachable,
        memory_api_reachable=memory_api_reachable,
        include_git_status=request.include_git_status,
    )

    lessons_stored = False
    if request.store_lessons and memory_api_reachable:
        lessons_stored = await store_lesson(settings, report)

    summary = {
        "source_root_available": source_root_available,
        "gateway_reachable": gateway_reachable,
        "memory_api_reachable": memory_api_reachable,
        "lessons_stored": lessons_stored,
    }
    report["summary"] = summary
    report_path = write_report(settings, report)

    return NightlyRunResponse(
        status="ok",
        mode=request.mode,
        report_path=str(report_path),
        summary=NightlyRunSummary(**summary),
    )


@app.get("/nightly/latest")
def nightly_latest() -> dict:
    settings = get_settings()
    latest = latest_report_metadata(settings)
    if latest is None:
        return {"status": "empty"}
    return latest
