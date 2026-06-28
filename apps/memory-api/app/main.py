from typing import Any

from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(title="MoE Memory API", version="0.1.0")


class HealthResponse(BaseModel):
    service: str
    status: str


class MemoryAddRequest(BaseModel):
    text: str
    source: str | None = None
    metadata: dict[str, Any] | None = None


class MemoryAddResponse(BaseModel):
    status: str
    message: str


class MemorySearchRequest(BaseModel):
    query: str
    limit: int = Field(default=5, ge=1)


class MemorySearchResponse(BaseModel):
    status: str
    results: list[dict[str, Any]]


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(service="memory-api", status="ok")


@app.post("/memory/add", response_model=MemoryAddResponse)
def add_memory(_: MemoryAddRequest) -> MemoryAddResponse:
    return MemoryAddResponse(
        status="accepted",
        message="memory add placeholder",
    )


@app.post("/memory/search", response_model=MemorySearchResponse)
def search_memory(_: MemorySearchRequest) -> MemorySearchResponse:
    return MemorySearchResponse(status="ok", results=[])
