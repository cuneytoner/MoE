from typing import Any, Literal

from pydantic import BaseModel


ModeName = Literal["coding", "image", "video", "3d_suite", "media_off"]


class HealthResponse(BaseModel):
    status: str
    service: str
    safe_actions_only: bool
    arbitrary_shell_enabled: bool
    apply_enabled: bool


class ModePlanRequest(BaseModel):
    mode: ModeName


class ModePlanResponse(BaseModel):
    status: str
    mode: str
    apply_supported: bool
    generation_host: str
    helper_host: str
    prompt_interpreter: str
    exclusive_gpu_mode: bool
    grouped_capabilities: list[str] = []
    start: list[str] = []
    stop: list[str] = []
    recommended_stop_for_vram: list[str] = []
    warnings: list[str] = []


class ApplyResponse(BaseModel):
    status: str
    mode: str | None = None
    apply_supported: bool = False
    reason: str
    plan: dict[str, Any] | None = None
