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


class GatewayRuntimeStatusResponse(BaseModel):
    status: str
    runtime_available: bool
    model_runtime_url: str
    loaded_models: list[dict[str, Any]]
    current_model: str | None = None


class GatewayRuntimeSwitchPlanRequest(BaseModel):
    message: str = Field(default="")
    intent: str | None = None
    target: str | None = None


class GatewayRuntimeSwitchPlanResponse(BaseModel):
    status: str
    intent: str
    target: str
    target_runtime_id: str | None = None
    current_runtime_model: str | None = None
    switch_required: bool
    manual_command: str
    reason: str


class GatewayToolPlan(BaseModel):
    recommended_tools: list[str]
    requires_runtime: bool
    requires_memory: bool
    safe_to_auto_run: bool
    reason: str


class GatewayToolsResponse(BaseModel):
    status: str
    tools: dict[str, dict[str, Any]]
    auto_execution_enabled: bool
    read_only_execution_enabled: bool


class GatewayToolExecuteRequest(BaseModel):
    tool: str = Field(min_length=1)
    arguments: dict[str, Any] = Field(default_factory=dict)


class GatewayToolExecuteResponse(BaseModel):
    status: str
    tool: str
    read_only: bool | None = None
    result: dict[str, Any] | None = None
    reason: str | None = None


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
    tool_plan: GatewayToolPlan


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
    tool_plan: GatewayToolPlan


class GatewayWorkspaceStatusResponse(BaseModel):
    status: str
    workspace_enabled: bool
    read_only: bool
    workspace_root: str | None = None
    max_file_bytes: int | None = None
    max_tree_items: int | None = None


class GatewayWorkspaceTreeItem(BaseModel):
    path: str
    type: str
    size: int | None = None


class GatewayWorkspaceTreeResponse(BaseModel):
    status: str
    path: str
    items: list[GatewayWorkspaceTreeItem] = Field(default_factory=list)
    truncated: bool = False
    reason: str | None = None


class GatewayWorkspaceFileResponse(BaseModel):
    status: str
    path: str
    size: int | None = None
    content: str | None = None
    reason: str | None = None


class GatewayWorkspaceSearchRequest(BaseModel):
    query: str = Field(min_length=1)
    path: str = "."
    max_results: int = Field(default=20, ge=1, le=100)


class GatewayWorkspaceSearchResult(BaseModel):
    path: str
    line: int
    snippet: str


class GatewayWorkspaceSearchResponse(BaseModel):
    status: str
    query: str | None = None
    path: str | None = None
    results: list[GatewayWorkspaceSearchResult] = Field(default_factory=list)
    truncated: bool = False
    reason: str | None = None


class GatewayWorkspaceContextRequest(BaseModel):
    task: str = Field(min_length=1)
    paths: list[str] = Field(min_length=1, max_length=20)
    max_chars: int = Field(default=12000, ge=1, le=50000)


class GatewayWorkspaceContextFile(BaseModel):
    path: str
    included: bool
    size: int | None = None
    reason: str | None = None
    truncated: bool | None = None


class GatewayWorkspaceContextResponse(BaseModel):
    status: str
    task: str
    context: str
    files: list[GatewayWorkspaceContextFile]
    truncated: bool


class OpenAIChatMessage(BaseModel):
    role: str
    content: str


class OpenAIChatCompletionRequest(BaseModel):
    model: str = "local-gateway"
    messages: list[OpenAIChatMessage] = Field(min_length=1)
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=8192)
    stream: bool = False


class OpenAIChatCompletionChoice(BaseModel):
    index: int
    message: OpenAIChatMessage
    finish_reason: str


class OpenAIChatCompletionUsage(BaseModel):
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0


class OpenAIChatCompletionResponse(BaseModel):
    id: str
    object: str
    created: int
    model: str
    choices: list[OpenAIChatCompletionChoice]
    usage: OpenAIChatCompletionUsage
