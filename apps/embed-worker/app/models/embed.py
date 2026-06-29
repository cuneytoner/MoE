from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    service: str
    status: str
    backend: str
    embedding_dim: int | None = None
    configured_embedding_dim: int | None = None
    runtime_embedding_dim: int | None = None
    model_path: str
    model_path_exists: bool
    model_loading: str
    model_loaded: bool | None = None


class EmbedRequest(BaseModel):
    text: str = Field(min_length=1)


class EmbedResponse(BaseModel):
    status: str
    backend: str
    embedding_dim: int
    vector: list[float]
