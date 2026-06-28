from qdrant_client import AsyncQdrantClient

from app.config import Settings


class QdrantClient:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def check(self) -> str:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=2)
        try:
            await client.get_collections()
        except Exception as exc:
            return f"unavailable: {exc.__class__.__name__}"
        finally:
            await client.close()

        return "ok"
