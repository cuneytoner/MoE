from app.clients.postgres import PostgresClient
from app.models.memory import MemoryAddRequest


class MemoryStore:
    def __init__(self, postgres: PostgresClient) -> None:
        self._postgres = postgres

    async def add(self, request: MemoryAddRequest) -> str:
        return await self._postgres.insert_memory(
            text=request.text,
            source=request.source,
            metadata=request.metadata or {},
        )
