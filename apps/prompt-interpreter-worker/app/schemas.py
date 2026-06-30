from typing import Literal

from pydantic import BaseModel, Field, field_validator


TargetMode = Literal["auto", "image", "video", "3d_suite", "3d_model", "rigging", "animation"]
Style = Literal["auto", "realistic", "technical", "cinematic", "product", "concept"]


class HealthResponse(BaseModel):
    status: str
    service: str
    mode: str
    model_enabled: bool
    generation_enabled: bool
    dry_run_default: bool


class InterpretRequest(BaseModel):
    prompt: str
    target_mode: TargetMode = "auto"
    style: Style = "auto"
    mode: str = "dry_run"

    @field_validator("prompt")
    @classmethod
    def prompt_must_be_valid(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("prompt must not be empty")
        if len(stripped) > 4000:
            raise ValueError("prompt must be 4000 characters or fewer")
        return stripped


class BatchInterpretRequest(BaseModel):
    items: list[InterpretRequest] = Field(default_factory=list)

    @field_validator("items")
    @classmethod
    def batch_size_limit(cls, value: list[InterpretRequest]) -> list[InterpretRequest]:
        if len(value) > 20:
            raise ValueError("batch may contain at most 20 items")
        return value
