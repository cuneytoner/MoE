from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(
        default="research-ingestion-worker",
        alias="RESEARCH_SERVICE_NAME",
    )
    host: str = Field(default="0.0.0.0", alias="RESEARCH_HOST")
    port: int = Field(default=8210, alias="RESEARCH_PORT")
    runtime_root: str = Field(
        default="/home/cuneyt/MoE/runtime",
        alias="RESEARCH_RUNTIME_ROOT",
    )
    reports_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/reports/research",
        alias="RESEARCH_REPORTS_DIR",
    )
    source_root: str = Field(default="/workspace", alias="RESEARCH_SOURCE_ROOT")
    sources_config: str = Field(
        default="/workspace/configs/research-sources.example.yaml",
        alias="RESEARCH_SOURCES_CONFIG",
    )
    memory_api_url: str = Field(
        default="http://memory-api:8101",
        alias="RESEARCH_MEMORY_API_URL",
    )
    gateway_url: str = Field(
        default="http://gateway-api:8100",
        alias="RESEARCH_GATEWAY_URL",
    )
    max_file_bytes: int = Field(
        default=200000,
        alias="RESEARCH_MAX_FILE_BYTES",
    )
    http_timeout_seconds: float = Field(
        default=2.0,
        alias="RESEARCH_HTTP_TIMEOUT_SECONDS",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
