from typing import Any

import httpx

from app.config import Settings


async def check_gateway(settings: Settings) -> bool:
    return await _check_health(f"{settings.gateway_url.rstrip('/')}/gateway/health", settings)


async def check_memory_api(settings: Settings) -> bool:
    return await _check_health(f"{settings.memory_api_url.rstrip('/')}/health", settings)


async def store_lesson(settings: Settings, report: dict[str, Any]) -> bool:
    lesson = {
        "text": _lesson_text(report),
        "source": "nightly-learning-worker",
        "metadata": {
            "service": report["service"],
            "mode": report["mode"],
            "created_at": report["created_at"],
            "report_path": report.get("report_path"),
        },
    }
    try:
        async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
            response = await client.post(
                f"{settings.memory_api_url.rstrip('/')}/memory/add",
                json=lesson,
            )
            return response.status_code < 400
    except httpx.HTTPError:
        return False


async def _check_health(url: str, settings: Settings) -> bool:
    try:
        async with httpx.AsyncClient(timeout=settings.http_timeout_seconds) as client:
            response = await client.get(url)
            return response.status_code < 400
    except httpx.HTTPError:
        return False


def _lesson_text(report: dict[str, Any]) -> str:
    observations = "; ".join(report.get("observations", []))
    recommendations = "; ".join(report.get("recommendations", []))
    return (
        "Nightly learning dry run completed. "
        f"Observations: {observations}. "
        f"Recommendations: {recommendations}."
    )
