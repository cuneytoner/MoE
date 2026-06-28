from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams

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

    async def ensure_collection(self) -> None:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=5)
        try:
            exists = await client.collection_exists(self._settings.qdrant_collection)
            if not exists:
                await client.create_collection(
                    collection_name=self._settings.qdrant_collection,
                    vectors_config=VectorParams(
                        size=self._settings.embedding_dim,
                        distance=Distance.COSINE,
                    ),
                )
        finally:
            await client.close()

    async def upsert_vector(
        self,
        vector_id: str,
        vector: list[float],
        payload: dict[str, object],
    ) -> None:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=10)
        try:
            await client.upsert(
                collection_name=self._settings.qdrant_collection,
                points=[
                    PointStruct(
                        id=vector_id,
                        vector=vector,
                        payload=payload,
                    )
                ],
            )
        finally:
            await client.close()
