from typing import Any

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    service: str
    status: str
    dependencies: dict[str, str]


class DeepHealthResponse(BaseModel):
    service: str
    status: str
    dependencies: dict[str, str]


class MemoryAddRequest(BaseModel):
    text: str
    source: str | None = None
    metadata: dict[str, Any] | None = None


class MemoryAddResponse(BaseModel):
    status: str
    id: str
    vector_id: str
    message: str


class MemorySearchRequest(BaseModel):
    query: str
    limit: int = Field(default=5, ge=1)


class MemorySearchResponse(BaseModel):
    status: str
    results: list[dict[str, Any]]
