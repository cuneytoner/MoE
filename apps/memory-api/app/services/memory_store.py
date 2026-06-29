from datetime import UTC, datetime
from re import sub
from uuid import uuid4

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.postgres import PostgresClient
from app.clients.qdrant import QdrantClient
from app.models.memory import MemoryAddRequest, MemorySearchRequest, MemorySearchResult


class MemoryStore:
    def __init__(
        self,
        embed_worker: EmbedWorkerClient,
        qdrant: QdrantClient,
        postgres: PostgresClient,
    ) -> None:
        self._embed_worker = embed_worker
        self._qdrant = qdrant
        self._postgres = postgres

    async def add(self, request: MemoryAddRequest) -> dict[str, str | int]:
        memory_id = str(uuid4())
        vector_id = str(uuid4())
        metadata = request.metadata or {}
        embedding = await self._embed_worker.embed(request.text)
        collection_name = resolve_collection_name(
            embedding.backend,
            embedding.embedding_dim,
        )

        created_at = datetime.now(UTC).isoformat()
        await self._qdrant.ensure_collection(collection_name, embedding.embedding_dim)
        await self._qdrant.upsert_vector(
            collection_name=collection_name,
            vector_id=vector_id,
            vector=embedding.vector,
            payload={
                "memory_id": memory_id,
                "text": request.text,
                "source": request.source,
                "metadata": metadata,
                "collection_name": collection_name,
                "embedding_backend": embedding.backend,
                "embedding_dim": embedding.embedding_dim,
                "created_at": created_at,
            },
        )

        stored_id = await self._postgres.insert_memory(
            memory_id=memory_id,
            text=request.text,
            source=request.source,
            metadata=metadata,
            vector_id=vector_id,
            collection_name=collection_name,
            embedding_backend=embedding.backend,
            embedding_dim=embedding.embedding_dim,
        )
        return {
            "id": stored_id,
            "vector_id": vector_id,
            "collection_name": collection_name,
            "embedding_backend": embedding.backend,
            "embedding_dim": embedding.embedding_dim,
        }

    async def search(
        self,
        request: MemorySearchRequest,
    ) -> tuple[str, str, int, list[MemorySearchResult]]:
        embedding = await self._embed_worker.embed(request.query)
        collection_name = resolve_collection_name(
            embedding.backend,
            embedding.embedding_dim,
        )

        exists = await self._qdrant.collection_exists(collection_name)
        if not exists:
            return collection_name, embedding.backend, embedding.embedding_dim, []

        await self._qdrant.ensure_collection(collection_name, embedding.embedding_dim)
        raw_results = await self._qdrant.search(
            collection_name=collection_name,
            query_vector=embedding.vector,
            limit=request.limit,
        )
        return (
            collection_name,
            embedding.backend,
            embedding.embedding_dim,
            [MemorySearchResult(**result) for result in raw_results],
        )


def resolve_collection_name(backend: str, embedding_dim: int) -> str:
    if backend == "fake" and embedding_dim == 384:
        return "moe_memories_fake_384"
    if backend == "bge-m3" and embedding_dim == 1024:
        return "moe_memories_bge_m3_1024"

    normalized_backend = sub(r"[^a-z0-9]+", "_", backend.lower()).strip("_")
    if not normalized_backend:
        normalized_backend = "unknown"
    return f"moe_memories_{normalized_backend}_{embedding_dim}"
