from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="memory-api", alias="SERVICE_NAME")
    memory_api_port: int = Field(default=8101, alias="MEMORY_API_PORT")

    postgres_host: str = Field(default="127.0.0.1", alias="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, alias="POSTGRES_PORT")
    postgres_db: str = Field(default="moe", alias="POSTGRES_DB")
    postgres_user: str = Field(default="moe", alias="POSTGRES_USER")
    postgres_password: str = Field(
        default="moe_dev_password",
        alias="POSTGRES_PASSWORD",
    )

    qdrant_host: str = Field(default="127.0.0.1", alias="QDRANT_HOST")
    qdrant_port: int = Field(default=6333, alias="QDRANT_PORT")
    qdrant_grpc_port: int = Field(default=6334, alias="QDRANT_GRPC_PORT")
    qdrant_collection: str = Field(default="moe_memories", alias="QDRANT_COLLECTION")
    embedding_dim: int = Field(default=384, alias="EMBEDDING_DIM")
    embed_worker_url: str = Field(
        default="http://localhost:8102",
        alias="EMBED_WORKER_URL",
    )

    @property
    def postgres_dsn(self) -> str:
        return (
            f"postgresql://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @property
    def qdrant_url(self) -> str:
        return f"http://{self.qdrant_host}:{self.qdrant_port}"


@lru_cache
def get_settings() -> Settings:
    return Settings()
