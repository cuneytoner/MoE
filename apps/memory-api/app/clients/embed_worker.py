from typing import Any

import httpx

from app.config import Settings


class EmbedWorkerClient:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def check(self) -> str:
        try:
            async with httpx.AsyncClient(timeout=2) as client:
                response = await client.get(
                    f"{self._settings.embed_worker_internal_url}/health"
                )
                response.raise_for_status()
        except Exception as exc:
            return f"unavailable: {exc.__class__.__name__}"

        return "ok"

    async def embed(self, text: str) -> list[float]:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                f"{self._settings.embed_worker_internal_url}/embed",
                json={"text": text},
            )
            response.raise_for_status()

        data: dict[str, Any] = response.json()
        vector = data.get("vector")
        if not isinstance(vector, list):
            raise ValueError("embed worker response missing vector")

        return [float(value) for value in vector]
