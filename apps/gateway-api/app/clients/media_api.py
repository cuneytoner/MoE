from typing import Any

import httpx


class MediaApiClient:
    def __init__(self, base_url: str) -> None:
        self._base_url = base_url.rstrip("/")

    async def check(self) -> str:
        try:
            async with httpx.AsyncClient(timeout=2) as client:
                response = await client.get(f"{self._base_url}/health")
                response.raise_for_status()
        except Exception as exc:
            return f"unavailable: {exc.__class__.__name__}"

        return "ok"

    async def create_job(self, job_spec: dict[str, Any]) -> dict[str, Any]:
        attempted_url = f"{self._base_url}/media/jobs"
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.post(attempted_url, json=job_spec)
                response.raise_for_status()
                data = response.json()
        except Exception as exc:
            return {
                "status": "rejected",
                "reason": (
                    "media api request failed: "
                    f"url={attempted_url} exception={exc.__class__.__name__}"
                ),
            }

        if isinstance(data, dict):
            return data
        return {"status": "rejected", "reason": "media api returned non-object response"}

    async def get_job(self, job_id: str) -> dict[str, Any]:
        attempted_url = f"{self._base_url}/media/jobs/{job_id}"
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(attempted_url)
                response.raise_for_status()
                data = response.json()
        except Exception as exc:
            return {
                "status": "rejected",
                "job_id": job_id,
                "reason": (
                    "media api request failed: "
                    f"url={attempted_url} exception={exc.__class__.__name__}"
                ),
            }

        if isinstance(data, dict):
            return data
        return {
            "status": "rejected",
            "job_id": job_id,
            "reason": "media api returned non-object response",
        }
