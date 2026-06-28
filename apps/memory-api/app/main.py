from fastapi import FastAPI, HTTPException

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
from app.services.memory_store import MemoryStore

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
async def add_memory(request: MemoryAddRequest) -> MemoryAddResponse:
    settings = get_settings()
    store = MemoryStore(PostgresClient(settings))

    try:
        memory_id = await store.add(request)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"postgres unavailable: {exc.__class__.__name__}",
        ) from exc

    return MemoryAddResponse(
        status="created",
        id=memory_id,
        message="memory stored without embedding",
    )


@app.post("/memory/search", response_model=MemorySearchResponse)
def search_memory(_: MemorySearchRequest) -> MemorySearchResponse:
    return MemorySearchResponse(status="ok", results=[])
