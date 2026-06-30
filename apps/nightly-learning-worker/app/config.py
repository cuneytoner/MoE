from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(
        default="nightly-learning-worker",
        alias="NIGHTLY_SERVICE_NAME",
    )
    host: str = Field(default="0.0.0.0", alias="NIGHTLY_HOST")
    port: int = Field(default=8200, alias="NIGHTLY_PORT")
    runtime_root: str = Field(
        default="/home/cuneyt/MoE/runtime",
        alias="NIGHTLY_RUNTIME_ROOT",
    )
    reports_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/reports/nightly",
        alias="NIGHTLY_REPORTS_DIR",
    )
    source_root: str = Field(default="/workspace", alias="NIGHTLY_SOURCE_ROOT")
    memory_api_url: str = Field(
        default="http://memory-api:8101",
        alias="NIGHTLY_MEMORY_API_URL",
    )
    gateway_url: str = Field(
        default="http://gateway-api:8100",
        alias="NIGHTLY_GATEWAY_URL",
    )
    http_timeout_seconds: float = Field(
        default=2.0,
        alias="NIGHTLY_HTTP_TIMEOUT_SECONDS",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
