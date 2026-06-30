from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator, model_validator

from app.image import validate_image_metadata

VALID_JOB_TYPES = {"image", "video", "3d", "rigging", "animation"}


class HealthResponse(BaseModel):
    status: str
    service: str
    dry_run_only: bool
    real_generation_enabled: bool = False
    media_root: str
    jobs_dir: str
    outputs_dir: str


class MediaJobRequest(BaseModel):
    job_type: str
    mode: str = "dry_run"
    prompt: str = Field(min_length=1, max_length=4000)
    negative_prompt: str = ""
    workflow: str = "default"
    metadata: dict[str, Any] = Field(default_factory=dict)

    @field_validator("job_type")
    @classmethod
    def validate_job_type(cls, value: str) -> str:
        if value not in VALID_JOB_TYPES:
            raise ValueError(f"job_type must be one of {sorted(VALID_JOB_TYPES)}")
        return value

    @model_validator(mode="after")
    def validate_metadata(self) -> "MediaJobRequest":
        if self.job_type == "image":
            ok, reason, normalized = validate_image_metadata(self.metadata)
            if not ok:
                raise ValueError(reason)
            self.metadata = normalized
        return self


class MediaJobSummary(BaseModel):
    job_id: str
    job_type: str
    mode: str
    state: str
    job_path: str


class MediaJobResponse(BaseModel):
    status: Literal["ok", "rejected"]
    job: MediaJobSummary | None = None
    reason: str | None = None


class DryRunProcessResponse(BaseModel):
    status: Literal["ok", "not_found", "rejected"]
    job_id: str
    report_path: str | None = None
    outputs: list[str] = []
    reason: str | None = None
