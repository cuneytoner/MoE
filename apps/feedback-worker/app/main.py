from typing import Literal

from fastapi import FastAPI, Query
from pydantic import BaseModel, Field, field_validator

from app.clients import check_memory_api, store_lesson
from app.config import get_settings
from app.gateway_summary import (
    feedback_status as gateway_feedback_status,
    summarize_feedback_file,
    write_summary,
)
from app.improvement import (
    build_improvement_report,
    latest_improvement_report_metadata,
    write_improvement_report,
)
from app.report import build_report, latest_report_metadata, write_report
from app.store import VALID_OUTCOMES, VALID_TASK_TYPES, append_event, read_events, summarize_events

app = FastAPI(title="MoE Feedback Worker", version="0.1.0")


class HealthResponse(BaseModel):
    status: str
    service: str
    data_dir: str
    events_file: str
    read_write_runtime_only: bool


class FeedbackEventRequest(BaseModel):
    task_id: str | None = None
    task_type: str = "unknown"
    goal: str = Field(min_length=1, max_length=1000)
    route_intent: str | None = None
    model_target: str | None = None
    actual_model: str | None = None
    tools: list[str] = Field(default_factory=list)
    selected_files: list[str] = Field(default_factory=list)
    tests_run: list[str] = Field(default_factory=list)
    outcome: str = "unknown"
    failure_reason: str | None = None
    notes: str | None = None

    @field_validator("task_type")
    @classmethod
    def validate_task_type(cls, value: str) -> str:
        if value not in VALID_TASK_TYPES:
            raise ValueError(f"task_type must be one of {sorted(VALID_TASK_TYPES)}")
        return value

    @field_validator("outcome")
    @classmethod
    def validate_outcome(cls, value: str) -> str:
        if value not in VALID_OUTCOMES:
            raise ValueError(f"outcome must be one of {sorted(VALID_OUTCOMES)}")
        return value


class FeedbackReportRequest(BaseModel):
    mode: str = "dry_run"
    limit: int = Field(default=100, ge=1, le=1000)
    store_lessons: bool = False


class ImprovementReportRequest(BaseModel):
    mode: str = "dry_run"
    limit: int = Field(default=100, ge=1, le=1000)
    include_router_recommendations: bool = True
    include_model_mapping_recommendations: bool = True
    include_prompt_recommendations: bool = True
    include_test_recommendations: bool = True
    store_lessons: bool = False


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        data_dir=settings.data_dir,
        events_file=settings.events_file,
        read_write_runtime_only=True,
    )


@app.post("/feedback/event")
def feedback_event(request: FeedbackEventRequest) -> dict:
    settings = get_settings()
    event = append_event(settings, request.model_dump())
    return {"status": "ok", "event": event}


@app.get("/feedback/events")
def feedback_events(
    limit: int = Query(default=20, ge=1, le=100),
    outcome: str | None = None,
) -> dict:
    settings = get_settings()
    if outcome and outcome not in VALID_OUTCOMES:
        return {"status": "rejected", "reason": "invalid outcome filter"}
    events = read_events(settings, limit=limit, outcome=outcome)
    if not events:
        return {"status": "empty", "events": []}
    return {"status": "ok", "order": "oldest_to_newest", "events": events}


@app.get("/feedback/status")
def feedback_bridge_status() -> dict:
    settings = get_settings()
    return gateway_feedback_status(settings.feedback_jsonl_path)


@app.post("/feedback/summarize")
def feedback_bridge_summarize() -> dict:
    settings = get_settings()
    summary = summarize_feedback_file(settings.feedback_jsonl_path)
    summary_path = write_summary(settings.feedback_summary_path, summary)
    return {
        "status": "ok",
        "service": settings.service_name,
        "summary_path": str(summary_path),
        "summary": summary,
    }


@app.post("/feedback/report")
async def feedback_report(request: FeedbackReportRequest) -> dict:
    settings = get_settings()
    if request.mode != "dry_run":
        return {
            "status": "rejected",
            "mode": request.mode,
            "reason": "only dry_run mode is supported",
        }

    events = read_events(settings, limit=request.limit)
    summary = summarize_events(events)
    report = build_report(settings, mode=request.mode, events=events, summary=summary)

    lessons_stored = False
    if request.store_lessons and await check_memory_api(settings):
        lessons_stored = await store_lesson(settings, report)

    report["summary"]["lessons_stored"] = lessons_stored
    report_path = write_report(settings, report)
    return {
        "status": "ok",
        "mode": request.mode,
        "report_path": str(report_path),
        "summary": report["summary"],
    }


@app.get("/feedback/latest-report")
def feedback_latest_report() -> dict:
    settings = get_settings()
    latest = latest_report_metadata(settings)
    if latest is None:
        return {"status": "empty"}
    return latest


@app.post("/improvement/report")
async def improvement_report(request: ImprovementReportRequest) -> dict:
    settings = get_settings()
    if request.mode != "dry_run":
        return {
            "status": "rejected",
            "mode": request.mode,
            "reason": "only dry_run mode is supported",
        }

    events = read_events(settings, limit=request.limit)
    report = build_improvement_report(
        settings,
        mode=request.mode,
        events=events,
        include_router_recommendations=request.include_router_recommendations,
        include_model_mapping_recommendations=request.include_model_mapping_recommendations,
        include_prompt_recommendations=request.include_prompt_recommendations,
        include_test_recommendations=request.include_test_recommendations,
    )

    lessons_stored = False
    if request.store_lessons and await check_memory_api(settings):
        lessons_stored = await store_lesson(settings, report)

    report["summary"]["lessons_stored"] = lessons_stored
    report_path = write_improvement_report(settings, report)
    return {
        "status": "ok",
        "mode": request.mode,
        "report_path": str(report_path),
        "summary": report["summary"],
        "apply_supported": False,
    }


@app.get("/improvement/latest-report")
def improvement_latest_report() -> dict:
    settings = get_settings()
    latest = latest_improvement_report_metadata(settings)
    if latest is None:
        return {"status": "empty"}
    return latest
