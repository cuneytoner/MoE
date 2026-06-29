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
    text: str = Field(min_length=1)
    source: str | None = None
    metadata: dict[str, Any] | None = None


class MemoryAddResponse(BaseModel):
    status: str
    id: str
    vector_id: str
    collection_name: str
    embedding_backend: str
    embedding_dim: int
    message: str


class MemorySearchRequest(BaseModel):
    query: str = Field(min_length=1)
    limit: int = Field(default=5, ge=1, le=100)


class MemorySearchResult(BaseModel):
    id: str
    vector_id: str | None = None
    score: float
    text: str | None = None
    source: str | None = None
    metadata: dict[str, Any]
    collection_name: str
    embedding_backend: str | None = None
    embedding_dim: int | None = None


class MemorySearchResponse(BaseModel):
    status: str
    collection_name: str
    embedding_backend: str
    embedding_dim: int
    results: list[MemorySearchResult]
