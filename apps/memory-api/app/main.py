from fastapi import FastAPI

from app.clients.postgres import PostgresClient
from app.clients.qdrant import QdrantClient
from app.config import get_settings
from app.models.memory import (
    DeepHealthResponse,
    HealthResponse,
    MemoryAddRequest,
    MemoryAddResponse,
    MemorySearchRequest,
    MemorySearchResponse,
)

app = FastAPI(title="MoE Memory API", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        service=settings.service_name,
        status="ok",
        dependencies={
            "postgres": "configured",
            "qdrant": "configured",
        },
    )


@app.get("/health/deep", response_model=DeepHealthResponse)
async def deep_health() -> DeepHealthResponse:
    settings = get_settings()
    dependencies = {
        "postgres": await PostgresClient(settings).check(),
        "qdrant": await QdrantClient(settings).check(),
    }
    status = "ok" if all(value == "ok" for value in dependencies.values()) else "degraded"

    return DeepHealthResponse(
        service=settings.service_name,
        status=status,
        dependencies=dependencies,
    )


@app.post("/memory/add", response_model=MemoryAddResponse)
def add_memory(_: MemoryAddRequest) -> MemoryAddResponse:
    return MemoryAddResponse(
        status="accepted",
        message="memory add placeholder",
    )


@app.post("/memory/search", response_model=MemorySearchResponse)
def search_memory(_: MemorySearchRequest) -> MemorySearchResponse:
    return MemorySearchResponse(status="ok", results=[])
