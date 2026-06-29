from functools import lru_cache
from pathlib import Path

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
    model_routing_config: str = Field(
        default_factory=lambda: _default_model_routing_config(),
        alias="MODEL_ROUTING_CONFIG",
    )
    workspace_root: str = Field(default="/workspace", alias="WORKSPACE_ROOT")
    workspace_enabled: bool = Field(default=True, alias="WORKSPACE_ENABLED")
    workspace_max_file_bytes: int = Field(
        default=200000,
        alias="WORKSPACE_MAX_FILE_BYTES",
    )
    workspace_max_tree_items: int = Field(
        default=500,
        alias="WORKSPACE_MAX_TREE_ITEMS",
    )
    workspace_allowed_extensions: str = Field(
        default=".py,.md,.txt,.yaml,.yml,.json,.toml,.sh,.env.example,.gitignore,.dockerignore,Dockerfile,Makefile",
        alias="WORKSPACE_ALLOWED_EXTENSIONS",
    )


def _default_model_routing_config() -> str:
    for parent in Path(__file__).resolve().parents:
        candidate = parent / "configs/model-routing.yaml"
        if candidate.exists():
            return str(candidate)
    return "/app/configs/model-routing.yaml"


@lru_cache
def get_settings() -> Settings:
    return Settings()
