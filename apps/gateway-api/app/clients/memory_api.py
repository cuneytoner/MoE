import httpx


class MemoryApiUnavailable(RuntimeError):
    pass


class MemoryApiClient:
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

    async def search(self, query: str, limit: int) -> dict[str, object]:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.post(
                    f"{self._base_url}/memory/search",
                    json={"query": query, "limit": limit},
                )
                response.raise_for_status()
        except Exception as exc:
            raise MemoryApiUnavailable(
                f"memory search unavailable at {self._base_url}: {exc.__class__.__name__}: {exc}"
            ) from exc

        data = response.json()
        if not isinstance(data, dict):
            raise MemoryApiUnavailable("memory search returned non-object response")
        return data
