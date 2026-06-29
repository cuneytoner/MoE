from typing import Any

from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams

from app.config import Settings


class QdrantCollectionError(ValueError):
    pass


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

    async def collection_exists(self, collection_name: str) -> bool:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=5)
        try:
            return bool(await client.collection_exists(collection_name))
        finally:
            await client.close()

    async def ensure_collection(self, collection_name: str, vector_size: int) -> None:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=5)
        try:
            exists = await client.collection_exists(collection_name)
            if not exists:
                await client.create_collection(
                    collection_name=collection_name,
                    vectors_config=VectorParams(
                        size=vector_size,
                        distance=Distance.COSINE,
                    ),
                )
                return

            existing_size = await self._collection_vector_size(client, collection_name)
            if existing_size != vector_size:
                raise QdrantCollectionError(
                    "Qdrant collection dimension mismatch: "
                    f"{collection_name} has size {existing_size}, requested {vector_size}"
                )
        finally:
            await client.close()

    async def upsert_vector(
        self,
        collection_name: str,
        vector_id: str,
        vector: list[float],
        payload: dict[str, object],
    ) -> None:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=10)
        try:
            await client.upsert(
                collection_name=collection_name,
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

    async def search(
        self,
        collection_name: str,
        query_vector: list[float],
        limit: int,
    ) -> list[dict[str, Any]]:
        client = AsyncQdrantClient(url=self._settings.qdrant_url, timeout=10)
        try:
            points = await self._search_points(
                client=client,
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit,
            )
        finally:
            await client.close()

        results: list[dict[str, Any]] = []
        for point in points:
            payload = self._value(point, "payload", {}) or {}
            point_id = self._value(point, "id")
            results.append(
                {
                    "id": str(payload.get("memory_id") or point_id),
                    "vector_id": str(point_id) if point_id is not None else None,
                    "score": float(self._value(point, "score", 0.0) or 0.0),
                    "text": payload.get("text"),
                    "source": payload.get("source"),
                    "metadata": payload.get("metadata") or {},
                    "collection_name": payload.get("collection_name") or collection_name,
                    "embedding_backend": payload.get("embedding_backend"),
                    "embedding_dim": payload.get("embedding_dim"),
                }
            )

        return results

    async def _collection_vector_size(
        self,
        client: AsyncQdrantClient,
        collection_name: str,
    ) -> int | None:
        collection = await client.get_collection(collection_name)
        vectors = self._nested_value(collection, ("config", "params", "vectors"))
        if isinstance(vectors, VectorParams):
            return vectors.size
        if isinstance(vectors, dict):
            default_vector = vectors.get("") or vectors.get("default") or vectors
            if isinstance(default_vector, VectorParams):
                return default_vector.size
            size = self._value(default_vector, "size")
            if isinstance(size, int):
                return size
        return None

    async def _search_points(
        self,
        client: AsyncQdrantClient,
        collection_name: str,
        query_vector: list[float],
        limit: int,
    ) -> list[Any]:
        if hasattr(client, "search"):
            return await client.search(
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit,
                with_payload=True,
            )

        response = await client.query_points(
            collection_name=collection_name,
            query=query_vector,
            limit=limit,
            with_payload=True,
        )
        points = self._value(response, "points", response)
        if points is None:
            return []
        return list(points)

    def _nested_value(self, value: Any, path: tuple[str, ...]) -> Any:
        current = value
        for key in path:
            current = self._value(current, key)
            if current is None:
                return None
        return current

    def _value(self, value: Any, key: str, default: Any = None) -> Any:
        if isinstance(value, dict):
            return value.get(key, default)
        return getattr(value, key, default)
