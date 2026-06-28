from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    service: str
    status: str
    backend: str
    embedding_dim: int
    model_path_configured: bool


class EmbedRequest(BaseModel):
    text: str = Field(min_length=1)


class EmbedResponse(BaseModel):
    status: str
    backend: str
    embedding_dim: int
    vector: list[float]
