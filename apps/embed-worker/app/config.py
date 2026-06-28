from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="embed-worker", alias="SERVICE_NAME")
    host: str = Field(default="0.0.0.0", alias="EMBED_WORKER_HOST")
    port: int = Field(default=8102, alias="EMBED_WORKER_PORT")
    backend: str = Field(default="fake", alias="EMBEDDING_BACKEND")
    embedding_dim: int = Field(default=384, alias="EMBEDDING_DIM")
    model_path: str = Field(
        default="/home/cuneyt/MoE_Models_Backup/bge-m3",
        alias="EMBEDDING_MODEL_PATH",
    )

    @property
    def model_path_configured(self) -> bool:
        return bool(self.model_path)


@lru_cache
def get_settings() -> Settings:
    return Settings()
