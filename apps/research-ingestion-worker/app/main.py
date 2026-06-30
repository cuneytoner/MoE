from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel

from app.clients import check_memory_api, store_findings
from app.config import get_settings
from app.ingestion import inspect_sources, load_sources
from app.report import build_report, latest_report_metadata, write_report

app = FastAPI(title="MoE Research Ingestion Worker", version="0.1.0")


class HealthResponse(BaseModel):
    status: str
    service: str
    runtime_reports_dir: str
    source_config_path: str
    approved_sources_only: bool
    read_only: bool


class ResearchRunRequest(BaseModel):
    mode: str = "dry_run"
    source_set: str = "default"
    store_findings: bool = False


class ResearchRunSummary(BaseModel):
    sources_loaded: int
    sources_processed: int
    sources_skipped: int
    findings_stored: bool


class ResearchRunResponse(BaseModel):
    status: Literal["ok", "rejected"]
    mode: str
    report_path: str | None = None
    summary: ResearchRunSummary | None = None
    reason: str | None = None


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        runtime_reports_dir=settings.reports_dir,
        source_config_path=settings.sources_config,
        approved_sources_only=True,
        read_only=True,
    )


@app.post("/research/run", response_model=ResearchRunResponse, response_model_exclude_none=True)
async def research_run(request: ResearchRunRequest) -> ResearchRunResponse:
    settings = get_settings()
    if request.mode != "dry_run":
        return ResearchRunResponse(
            status="rejected",
            mode=request.mode,
            reason="only dry_run mode is supported",
        )

    loaded_sources = load_sources(settings, request.source_set)
    inspected_sources = inspect_sources(settings, loaded_sources)
    report = build_report(
        settings,
        mode=request.mode,
        source_set=request.source_set,
        sources=inspected_sources,
    )

    findings_stored = False
    if request.store_findings and await check_memory_api(settings):
        findings_stored = await store_findings(settings, report)

    processed = [source for source in inspected_sources if source.get("status") == "processed"]
    skipped = [source for source in inspected_sources if source.get("status") == "skipped"]
    summary = {
        "sources_loaded": len(loaded_sources),
        "sources_processed": len(processed),
        "sources_skipped": len(skipped),
        "findings_stored": findings_stored,
    }
    report["summary"] = summary
    report_path = write_report(settings, report)

    return ResearchRunResponse(
        status="ok",
        mode=request.mode,
        report_path=str(report_path),
        summary=ResearchRunSummary(**summary),
    )


@app.get("/research/latest")
def research_latest() -> dict:
    settings = get_settings()
    latest = latest_report_metadata(settings)
    if latest is None:
        return {"status": "empty"}
    return latest
