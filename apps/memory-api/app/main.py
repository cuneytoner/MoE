import logging

from fastapi import FastAPI, HTTPException

from app.clients.embed_worker import EmbedWorkerClient
from app.clients.postgres import PostgresClient
from app.clients.qdrant import QdrantClient, QdrantCollectionError
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
logger = logging.getLogger(__name__)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        service=settings.service_name,
        status="ok",
        dependencies={
            "postgres": "configured",
            "qdrant": "configured",
            "embed_worker": "configured",
        },
    )


@app.get("/health/deep", response_model=DeepHealthResponse)
async def deep_health() -> DeepHealthResponse:
    settings = get_settings()
    dependencies = {
        "postgres": await PostgresClient(settings).check(),
        "qdrant": await QdrantClient(settings).check(),
        "embed_worker": await EmbedWorkerClient(settings).check(),
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
    store = MemoryStore(
        embed_worker=EmbedWorkerClient(settings),
        qdrant=QdrantClient(settings),
        postgres=PostgresClient(settings),
    )

    try:
        result = await store.add(request)
    except QdrantCollectionError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("memory storage failed")
        raise HTTPException(
            status_code=503,
            detail=f"memory storage unavailable: {exc.__class__.__name__}: {exc}",
        ) from exc

    return MemoryAddResponse(
        status="created",
        id=str(result["id"]),
        vector_id=str(result["vector_id"]),
        collection_name=str(result["collection_name"]),
        embedding_backend=str(result["embedding_backend"]),
        embedding_dim=int(result["embedding_dim"]),
        message="memory stored with embedding",
    )


@app.post("/memory/search", response_model=MemorySearchResponse)
async def search_memory(request: MemorySearchRequest) -> MemorySearchResponse:
    settings = get_settings()
    store = MemoryStore(
        embed_worker=EmbedWorkerClient(settings),
        qdrant=QdrantClient(settings),
        postgres=PostgresClient(settings),
    )

    try:
        collection_name, backend, embedding_dim, results = await store.search(request)
    except QdrantCollectionError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("memory search failed")
        raise HTTPException(
            status_code=503,
            detail=f"memory search unavailable: {exc.__class__.__name__}: {exc}",
        ) from exc

    return MemorySearchResponse(
        status="ok",
        collection_name=collection_name,
        embedding_backend=backend,
        embedding_dim=embedding_dim,
        results=results,
    )
