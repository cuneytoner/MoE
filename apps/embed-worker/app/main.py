from fastapi import FastAPI

from app.config import get_settings
from app.models.embed import EmbedRequest, EmbedResponse, HealthResponse
from app.services.fake_embedder import FakeEmbedder


app = FastAPI(title="MoE Embed Worker", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        service=settings.service_name,
        status="ok",
        backend=settings.backend,
        embedding_dim=settings.embedding_dim,
        model_path_configured=settings.model_path_configured,
    )


@app.post("/embed", response_model=EmbedResponse)
def embed(request: EmbedRequest) -> EmbedResponse:
    settings = get_settings()
    embedder = FakeEmbedder(settings.embedding_dim)
    vector = embedder.embed(request.text)

    return EmbedResponse(
        status="ok",
        backend=settings.backend,
        embedding_dim=settings.embedding_dim,
        vector=vector,
    )
