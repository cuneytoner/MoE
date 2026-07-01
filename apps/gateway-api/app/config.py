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
    media_api_url: str = Field(default="http://media-api:8300", alias="MEDIA_API_URL")
    media_api_public_url: str = Field(
        default="http://localhost:8300",
        alias="MEDIA_API_PUBLIC_URL",
    )
    media_worker_url: str = Field(
        default="http://media-worker:8310",
        alias="MEDIA_WORKER_URL",
    )
    prompt_interpreter_url: str = Field(
        default="http://192.168.50.2:8230",
        alias="PROMPT_INTERPRETER_URL",
    )
    gateway_media_enabled: bool = Field(default=True, alias="GATEWAY_MEDIA_ENABLED")
    gateway_media_real_allowed: bool = Field(
        default=False,
        alias="GATEWAY_MEDIA_REAL_ALLOWED",
    )
    gateway_media_default_mode: str = Field(
        default="dry_run",
        alias="GATEWAY_MEDIA_DEFAULT_MODE",
    )
    media_dashboard_enabled: bool = Field(
        default=True,
        alias="MEDIA_DASHBOARD_ENABLED",
    )
    media_outputs_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/media/outputs",
        alias="MEDIA_OUTPUTS_DIR",
    )
    media_dashboard_max_images: int = Field(
        default=20,
        alias="MEDIA_DASHBOARD_MAX_IMAGES",
    )
    control_api_url: str = Field(
        default="http://host.docker.internal:8400",
        alias="CONTROL_API_URL",
    )
    comfyui_url: str = Field(
        default="http://host.docker.internal:8188",
        alias="COMFYUI_URL",
    )
    runtime_dashboard_enabled: bool = Field(
        default=True,
        alias="RUNTIME_DASHBOARD_ENABLED",
    )
    media_jobs_dir: str = Field(
        default="/home/cuneyt/MoE/runtime/media/jobs",
        alias="MEDIA_JOBS_DIR",
    )
    runtime_dashboard_max_jobs: int = Field(
        default=5,
        alias="RUNTIME_DASHBOARD_MAX_JOBS",
    )
    llama_server_url: str = Field(
        default="http://host.docker.internal:8000",
        alias="LLAMA_SERVER_URL",
    )
    llama_server_base_url: str = Field(
        default="http://host.docker.internal:8000",
        alias="LLAMA_SERVER_BASE_URL",
    )
    gateway_chat_timeout_seconds: float = Field(
        default=120.0,
        alias="GATEWAY_CHAT_TIMEOUT_SECONDS",
    )
    pc2_prompt_interpreter_url: str = Field(
        default="http://192.168.50.2:8230",
        alias="PC2_PROMPT_INTERPRETER_URL",
    )
    pc2_nightly_url: str = Field(
        default="http://192.168.50.2:8200",
        alias="PC2_NIGHTLY_URL",
    )
    pc2_research_url: str = Field(
        default="http://192.168.50.2:8210",
        alias="PC2_RESEARCH_URL",
    )
    pc2_feedback_url: str = Field(
        default="http://192.168.50.2:8220",
        alias="PC2_FEEDBACK_URL",
    )
    docker_summary_snapshot_path: str = Field(
        default="/home/cuneyt/MoE/runtime/status/docker-summary.json",
        alias="DOCKER_SUMMARY_SNAPSHOT_PATH",
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
