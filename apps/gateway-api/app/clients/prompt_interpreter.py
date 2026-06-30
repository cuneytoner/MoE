from typing import Any

import httpx


class PromptInterpreterClient:
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

    async def interpret(
        self,
        prompt: str,
        target_mode: str,
        style: str,
    ) -> tuple[dict[str, Any] | None, str | None]:
        attempted_url = f"{self._base_url}/interpret"
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.post(
                    attempted_url,
                    json={
                        "prompt": prompt,
                        "target_mode": target_mode,
                        "style": style,
                        "mode": "dry_run",
                    },
                )
                response.raise_for_status()
                data = response.json()
        except Exception as exc:
            return None, (
                "prompt interpreter unavailable: "
                f"url={attempted_url} exception={exc.__class__.__name__}"
            )

        if not isinstance(data, dict):
            return None, "prompt interpreter returned non-object response"
        if data.get("status") != "ok":
            return None, str(data.get("reason") or "prompt interpreter rejected request")
        return data, None
