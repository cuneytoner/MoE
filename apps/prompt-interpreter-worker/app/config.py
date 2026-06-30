from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    service_name: str = "prompt-interpreter-worker"
    runtime_root: str = "/home/cuneyt/MoE/runtime"
    mode: str = "rule_based"
    model_enabled: bool = False
    generation_enabled: bool = False
    default_mode: str = "dry_run"

    model_config = SettingsConfigDict(env_prefix="PROMPT_INTERPRETER_", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
