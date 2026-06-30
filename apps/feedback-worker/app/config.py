from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")

    service_name: str = Field(default="feedback-worker", alias="FEEDBACK_SERVICE_NAME")
    host: str = Field(default="0.0.0.0", alias="FEEDBACK_HOST")
    port: int = Field(default=8220, alias="FEEDBACK_PORT")
    runtime_root: str = Field(
        default="/home/cuneyt/MoE/runtime",
        alias="FEEDBACK_RUNTIME_ROOT",
    )
    data_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/feedback",
        alias="FEEDBACK_DATA_DIR",
    )
    events_file: str = Field(
        default="/home/cuneyt/MoE/runtime/feedback/events.jsonl",
        alias="FEEDBACK_EVENTS_FILE",
    )
    reports_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/reports/feedback",
        alias="FEEDBACK_REPORTS_DIR",
    )
    memory_api_url: str = Field(
        default="http://memory-api:8101",
        alias="FEEDBACK_MEMORY_API_URL",
    )
    http_timeout_seconds: float = Field(
        default=2.0,
        alias="FEEDBACK_HTTP_TIMEOUT_SECONDS",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
