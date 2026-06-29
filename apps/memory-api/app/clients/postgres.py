import json
from typing import Any

import asyncpg

from app.config import Settings


class PostgresClient:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def check(self) -> str:
        try:
            connection = await asyncpg.connect(
                dsn=self._settings.postgres_dsn,
                timeout=2,
            )
            try:
                await connection.execute("SELECT 1")
            finally:
                await connection.close()
        except Exception as exc:
            return f"unavailable: {exc.__class__.__name__}"

        return "ok"

    async def insert_memory(
        self,
        memory_id: str,
        text: str,
        source: str | None,
        metadata: dict[str, Any],
        vector_id: str | None,
        collection_name: str,
        embedding_backend: str,
        embedding_dim: int,
    ) -> str:
        connection = await asyncpg.connect(
            dsn=self._settings.postgres_dsn,
            timeout=5,
        )
        try:
            columns = await self._memory_columns(connection)
            if {
                "collection_name",
                "embedding_backend",
                "embedding_dim",
            }.issubset(columns):
                memory_id = await connection.fetchval(
                    """
                    INSERT INTO memories (
                      id,
                      text,
                      source,
                      metadata,
                      vector_id,
                      collection_name,
                      embedding_backend,
                      embedding_dim
                    )
                    VALUES ($1::uuid, $2, $3, $4::jsonb, $5, $6, $7, $8)
                    RETURNING id::text
                    """,
                    memory_id,
                    text,
                    source,
                    json.dumps(metadata),
                    vector_id,
                    collection_name,
                    embedding_backend,
                    embedding_dim,
                )
            else:
                memory_id = await connection.fetchval(
                    """
                    INSERT INTO memories (id, text, source, metadata, vector_id)
                    VALUES ($1::uuid, $2, $3, $4::jsonb, $5)
                    RETURNING id::text
                    """,
                    memory_id,
                    text,
                    source,
                    json.dumps(metadata),
                    vector_id,
                )
        finally:
            await connection.close()

        return str(memory_id)

    async def _memory_columns(self, connection: asyncpg.Connection) -> set[str]:
        rows = await connection.fetch(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'memories'
            """
        )
        return {str(row["column_name"]) for row in rows}
