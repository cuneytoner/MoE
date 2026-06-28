from datetime import UTC, datetime
from uuid import uuid4

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.postgres import PostgresClient
from app.clients.qdrant import QdrantClient
from app.models.memory import MemoryAddRequest


class MemoryStore:
    def __init__(
        self,
        embed_worker: EmbedWorkerClient,
        qdrant: QdrantClient,
        postgres: PostgresClient,
        embedding_dim: int,
    ) -> None:
        self._embed_worker = embed_worker
        self._qdrant = qdrant
        self._postgres = postgres
        self._embedding_dim = embedding_dim

    async def add(self, request: MemoryAddRequest) -> tuple[str, str]:
        memory_id = str(uuid4())
        vector_id = str(uuid4())
        metadata = request.metadata or {}
        vector = await self._embed_worker.embed(request.text)

        if len(vector) != self._embedding_dim:
            raise ValueError(
                f"embedding dimension mismatch: expected {self._embedding_dim}, got {len(vector)}"
            )

        created_at = datetime.now(UTC).isoformat()
        await self._qdrant.ensure_collection()
        await self._qdrant.upsert_vector(
            vector_id=vector_id,
            vector=vector,
            payload={
                "memory_id": memory_id,
                "text": request.text,
                "source": request.source,
                "metadata": metadata,
                "created_at": created_at,
            },
        )

        stored_id = await self._postgres.insert_memory(
            memory_id=memory_id,
            text=request.text,
            source=request.source,
            metadata=metadata,
            vector_id=vector_id,
        )
        return stored_id, vector_id
