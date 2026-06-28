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
