from typing import Any

import httpx
from pydantic import BaseModel

from app.config import Settings


class EmbedResult(BaseModel):
    backend: str
    embedding_dim: int
    vector: list[float]


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

    async def embed(self, text: str) -> EmbedResult:
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

        backend = data.get("backend")
        if not isinstance(backend, str) or not backend:
            raise ValueError("embed worker response missing backend")

        embedding_dim = data.get("embedding_dim")
        if not isinstance(embedding_dim, int):
            raise ValueError("embed worker response missing embedding_dim")

        normalized_vector = [float(value) for value in vector]
        if len(normalized_vector) != embedding_dim:
            raise ValueError(
                f"embed worker dimension mismatch: reported {embedding_dim}, got {len(normalized_vector)}"
            )

        return EmbedResult(
            backend=backend,
            embedding_dim=embedding_dim,
            vector=normalized_vector,
        )
