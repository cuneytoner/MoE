from fastapi import FastAPI, HTTPException

from app.config import get_settings
from app.models.embed import EmbedRequest, EmbedResponse, HealthResponse
from app.services.embedder_factory import create_embedder


app = FastAPI(title="MoE Embed Worker", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        service=settings.service_name,
        status="ok",
        backend=settings.backend,
        embedding_dim=settings.embedding_dim,
        model_path=settings.model_path,
        model_path_exists=settings.model_path_exists,
        model_loading=settings.model_loading,
    )


@app.post("/embed", response_model=EmbedResponse)
def embed(request: EmbedRequest) -> EmbedResponse:
    settings = get_settings()
    embedder = create_embedder(settings)

    try:
        vector = embedder.embed(request.text)
    except NotImplementedError as exc:
        raise HTTPException(status_code=501, detail=str(exc)) from exc

    return EmbedResponse(
        status="ok",
        backend=embedder.backend,
        embedding_dim=settings.embedding_dim,
        vector=vector,
    )
