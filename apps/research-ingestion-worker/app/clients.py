from typing import Any

import httpx

from app.config import Settings


async def check_memory_api(settings: Settings) -> bool:
    try:
        async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
            response = await client.get(f"{settings.memory_api_url.rstrip('/')}/health")
            return response.status_code < 400
    except httpx.HTTPError:
        return False


async def store_findings(settings: Settings, report: dict[str, Any]) -> bool:
    findings = {
        "text": _findings_text(report),
        "source": "research-ingestion-worker",
        "metadata": {
            "service": report["service"],
            "mode": report["mode"],
            "created_at": report["created_at"],
            "source_set": report["source_set"],
            "report_path": report.get("report_path"),
        },
    }
    try:
        async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
            response = await client.post(
                f"{settings.memory_api_url.rstrip('/')}/memory/add",
                json=findings,
            )
            return response.status_code < 400
    except httpx.HTTPError:
        return False


def _findings_text(report: dict[str, Any]) -> str:
    processed = [
        source["id"]
        for source in report.get("sources", [])
        if source.get("status") == "processed"
    ]
    skipped = [
        source["id"]
        for source in report.get("sources", [])
        if source.get("status") == "skipped"
    ]
    return (
        "Research ingestion dry run completed. "
        f"Processed sources: {', '.join(processed) or 'none'}. "
        f"Skipped sources: {', '.join(skipped) or 'none'}."
    )
