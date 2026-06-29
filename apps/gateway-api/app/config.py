from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="gateway-api", alias="SERVICE_NAME")
    gateway_api_host: str = Field(default="0.0.0.0", alias="GATEWAY_API_HOST")
    gateway_api_port: int = Field(default=8100, alias="GATEWAY_API_PORT")

    memory_api_url: str = Field(default="http://localhost:8101", alias="MEMORY_API_URL")
    embed_worker_url: str = Field(default="http://localhost:8102", alias="EMBED_WORKER_URL")
    model_runtime_url: str = Field(
        default="http://localhost:8000/v1",
        alias="MODEL_RUNTIME_URL",
    )
    model_runtime_public_url: str = Field(
        default="http://localhost:8000/v1",
        alias="MODEL_RUNTIME_PUBLIC_URL",
    )
    default_model: str = Field(default="deepseek-coder-lite", alias="DEFAULT_MODEL")


@lru_cache
def get_settings() -> Settings:
    return Settings()
