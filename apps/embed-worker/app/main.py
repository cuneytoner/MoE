from fastapi import FastAPI, HTTPException

from app.config import get_settings
from app.models.embed import EmbedRequest, EmbedResponse, HealthResponse
from app.services.bge_m3_embedder import BgeM3Embedder
from app.services.embedder_factory import create_embedder


app = FastAPI(title="MoE Embed Worker", version="0.1.0")


@app.get("/health", response_model=HealthResponse, response_model_exclude_none=True)
def health() -> HealthResponse:
    settings = get_settings()
    runtime_dim = BgeM3Embedder.runtime_dimension(settings.model_path)
    return HealthResponse(
        service=settings.service_name,
        status="ok",
        backend=settings.backend,
        embedding_dim=settings.embedding_dim,
        configured_embedding_dim=settings.embedding_dim,
        runtime_embedding_dim=runtime_dim,
        model_path=settings.model_path,
        model_path_exists=settings.model_path_exists,
        model_loading=settings.model_loading,
        model_loaded=BgeM3Embedder.is_loaded(settings.model_path)
        if settings.backend == "bge-m3"
        else None,
    )


@app.post("/embed", response_model=EmbedResponse)
def embed(request: EmbedRequest) -> EmbedResponse:
    settings = get_settings()
    embedder = create_embedder(settings)

    try:
        vector = embedder.embed(request.text)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return EmbedResponse(
        status="ok",
        backend=embedder.backend,
        embedding_dim=len(vector),
        vector=vector,
    )
