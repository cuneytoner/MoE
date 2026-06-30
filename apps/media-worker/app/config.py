from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="media-worker", alias="MEDIA_WORKER_SERVICE_NAME")
    host: str = Field(default="0.0.0.0", alias="MEDIA_WORKER_HOST")
    port: int = Field(default=8310, alias="MEDIA_WORKER_PORT")
    jobs_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/media/jobs",
        alias="MEDIA_JOBS_DIR",
    )
    reports_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/reports/media",
        alias="MEDIA_REPORTS_DIR",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
