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


async def store_lesson(settings: Settings, report: dict[str, Any]) -> bool:
    summary = report.get("summary", {})
    lesson = {
        "text": (
            "Feedback report generated. "
            f"Total events: {summary.get('total', 0)}. "
            f"Successes: {summary.get('success', 0)}. "
            f"Failures: {summary.get('failure', 0)}."
        ),
        "source": "feedback-worker",
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
