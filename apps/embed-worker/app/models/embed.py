from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    service: str
    status: str
    backend: str
    embedding_dim: int
    model_path: str
    model_path_exists: bool
    model_loading: str


class EmbedRequest(BaseModel):
    text: str = Field(min_length=1)


class EmbedResponse(BaseModel):
    status: str
    backend: str
    embedding_dim: int
    vector: list[float]
