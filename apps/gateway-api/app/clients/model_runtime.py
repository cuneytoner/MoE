from typing import Any

import httpx


class ModelRuntimeUnavailable(RuntimeError):
    pass


class ModelRuntimeClient:
    def __init__(self, base_url: str) -> None:
        self._base_url = base_url.rstrip("/")

    async def check(self) -> str:
        try:
            await self.list_models()
        except Exception as exc:
            return f"unavailable: {exc.__class__.__name__}"

        return "ok"

    async def list_models(self) -> list[dict[str, Any]]:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self._base_url}/models")
                response.raise_for_status()
        except Exception as exc:
            raise ModelRuntimeUnavailable(
                f"model runtime unavailable at {self._base_url}: {exc.__class__.__name__}: {exc}"
            ) from exc

        data = response.json()
        models = data.get("data", data if isinstance(data, list) else [])
        if not isinstance(models, list):
            return []

        normalized: list[dict[str, Any]] = []
        for model in models:
            if isinstance(model, dict):
                normalized.append(model)
            else:
                normalized.append({"id": str(model)})
        return normalized

    async def chat(
        self,
        model: str,
        messages: list[dict[str, str]],
        temperature: float,
        max_tokens: int,
    ) -> dict[str, Any]:
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        try:
            async with httpx.AsyncClient(timeout=120) as client:
                response = await client.post(
                    f"{self._base_url}/chat/completions",
                    json=payload,
                )
                response.raise_for_status()
        except Exception as exc:
            raise ModelRuntimeUnavailable(
                f"model runtime chat unavailable at {self._base_url}: {exc.__class__.__name__}: {exc}"
            ) from exc

        return response.json()
