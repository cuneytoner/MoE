from app.config import Settings
from app.services.bge_m3_embedder import BgeM3Embedder
from app.services.fake_embedder import FakeEmbedder


def create_embedder(settings: Settings) -> FakeEmbedder | BgeM3Embedder:
    if settings.backend == "fake":
        return FakeEmbedder(settings.embedding_dim)
    if settings.backend == "bge-m3":
        return BgeM3Embedder(settings.model_path)

    raise ValueError(f"unsupported embedding backend: {settings.backend}")
