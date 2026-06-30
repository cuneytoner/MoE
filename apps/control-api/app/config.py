from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    service_name: str = "control-api"
    runtime_root: str = "/home/cuneyt/MoE/runtime"
    mode_config_path: str = str(REPO_ROOT / "configs/runtime-modes.example.yaml")
    allow_apply: bool = False

    model_config = SettingsConfigDict(env_prefix="CONTROL_", extra="ignore")

    @property
    def runtime_path(self) -> Path:
        return Path(self.runtime_root)


@lru_cache
def get_settings() -> Settings:
    return Settings()
