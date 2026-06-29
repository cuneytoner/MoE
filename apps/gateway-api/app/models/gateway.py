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


class GatewayModelRoutingResponse(BaseModel):
    status: str
    default_model_target: str
    fallback_model_target: str
    intent_model_targets: dict[str, str]
    model_targets: dict[str, dict[str, Any]]


class GatewayChatRequest(BaseModel):
    message: str = Field(min_length=1)
    system: str | None = None
    model: str | None = None
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=8192)
    use_memory: bool = False
    memory_limit: int = Field(default=5, ge=1, le=20)
    auto_route: bool = True


class GatewayChatMemory(BaseModel):
    enabled: bool
    status: str
    results_count: int
    collection_name: str | None = None
    embedding_backend: str | None = None
    embedding_dim: int | None = None


class GatewayRouteMetadata(BaseModel):
    intent: str
    confidence: float
    model_target: str
    model_target_runtime_id: str | None = None
    model_mapping_status: str
    use_memory_recommended: bool
    reason: str
    signals: dict[str, Any]


class GatewayModelAlignment(BaseModel):
    target: str
    target_runtime_id: str | None = None
    actual: str
    matched: bool
    reason: str


class GatewayChatResponse(BaseModel):
    status: str
    model: str
    content: str
    route: GatewayRouteMetadata
    model_alignment: GatewayModelAlignment
    memory: GatewayChatMemory
    raw: dict[str, Any] | None = None


class GatewayRouteRequest(BaseModel):
    message: str = Field(min_length=1)
    use_memory: bool = False


class GatewayRouteResponse(BaseModel):
    status: str
    intent: str
    confidence: float
    model_target: str
    model_target_runtime_id: str | None = None
    model_mapping_status: str
    use_memory_recommended: bool
    memory_enabled: bool
    reason: str
    signals: dict[str, Any]
