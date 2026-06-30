from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="media-api", alias="MEDIA_SERVICE_NAME")
    host: str = Field(default="0.0.0.0", alias="MEDIA_API_HOST")
    port: int = Field(default=8300, alias="MEDIA_API_PORT")
    runtime_root: str = Field(
        default="/home/cuneyt/MoE/runtime",
        alias="MEDIA_RUNTIME_ROOT",
    )
    media_root: str = Field(
        default="/home/cuneyt/MoE/runtime/media",
        alias="MEDIA_ROOT",
    )
    jobs_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/media/jobs",
        alias="MEDIA_JOBS_DIR",
    )
    outputs_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/media/outputs",
        alias="MEDIA_OUTPUTS_DIR",
    )
    reports_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/reports/media",
        alias="MEDIA_REPORTS_DIR",
    )
    media_worker_url: str = Field(
        default="http://media-worker:8310",
        alias="MEDIA_WORKER_URL",
    )
    real_generation_enabled: bool = Field(
        default=False,
        alias="MEDIA_REAL_GENERATION_ENABLED",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
