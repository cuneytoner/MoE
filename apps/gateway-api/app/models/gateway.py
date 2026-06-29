from typing import Any

from pydantic import BaseModel, Field


class GatewayHealthResponse(BaseModel):
    service: str
    status: str
    dependencies: dict[str, str]


class GatewayModelsResponse(BaseModel):
    status: str
    model_runtime_url: str
    models: list[dict[str, Any]]


class GatewayChatRequest(BaseModel):
    message: str = Field(min_length=1)
    system: str | None = None
    model: str | None = None
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=8192)
    use_memory: bool = False
    memory_limit: int = Field(default=5, ge=1, le=20)


class GatewayChatMemory(BaseModel):
    enabled: bool
    status: str
    results_count: int
    collection_name: str | None = None
    embedding_backend: str | None = None
    embedding_dim: int | None = None


class GatewayChatResponse(BaseModel):
    status: str
    model: str
    content: str
    memory: GatewayChatMemory
    raw: dict[str, Any] | None = None


class GatewayRouteRequest(BaseModel):
    message: str = Field(min_length=1)
    use_memory: bool = False


class GatewayRouteResponse(BaseModel):
    status: str
    intent: str
    model_target: str
    memory_enabled: bool
