from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


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


class GatewayRuntimeProfilePreflightProfile(BaseModel):
    model_target: str
    runtime_model_id: str | None = None
    mapping_status: str
    file_path: str | None = None
    file_exists: bool | None = None
    readiness: Literal["ready", "missing_file", "unknown", "review_required"]
    warnings: list[str] = Field(default_factory=list)


class GatewayRuntimeProfilePreflightResponse(BaseModel):
    status: Literal["ok", "review_required"]
    service: Literal["gateway-runtime-profile-preflight"]
    read_only: bool = True
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    model_runtime_url: str
    active_model: str | None = None
    profiles: list[GatewayRuntimeProfilePreflightProfile]


class GatewayRuntimeProfileRunCatalogProfile(BaseModel):
    model_target: str
    runtime_model_id: str | None = None
    model_config_id: str | None = None
    model_path: str | None = None
    context: int | None = None
    gpu_layers: int | None = None
    threads: int | None = None
    batch_size: int | None = None
    ubatch_size: int | None = None
    cache_type_k: str | None = None
    cache_type_v: str | None = None
    flash_attention: bool | None = None
    readiness_hint: str
    warnings: list[str] = Field(default_factory=list)
    manual_run_reference: str


class GatewayRuntimeProfileRunCatalogResponse(BaseModel):
    status: Literal["ok", "review_required"]
    service: Literal["gateway-runtime-profile-run-catalog"]
    read_only: bool = True
    documentation_only: bool = True
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    auto_execution_supported: bool = False
    runbook: Literal["docs/gateway-runtime-switch-runbook.md"]
    profiles: list[GatewayRuntimeProfileRunCatalogProfile]


class GatewayRuntimeHardwareProfile(BaseModel):
    name: Literal["pc1-rtx-5060-ti-16gb"]
    gpu: Literal["NVIDIA RTX 5060 Ti"]
    vram_gb: int
    ram_gb: int
    cpu: Literal["AMD Ryzen 7 7800X3D"]


class GatewayRuntimeProfileCompatibilityProfile(BaseModel):
    model_target: str
    model_config_id: str | None = None
    runtime_model_id: str | None = None
    context: int | None = None
    gpu_layers: int | None = None
    batch_size: int | None = None
    ubatch_size: int | None = None
    compatibility: Literal["compatible", "borderline", "review_required", "unknown"]
    risk_level: Literal["low", "medium", "high", "unknown"]
    estimated_vram_pressure: Literal["low", "medium", "high", "unknown"]
    notes: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)


class GatewayRuntimeProfileCompatibilityMatrixResponse(BaseModel):
    status: Literal["ok", "review_required"]
    service: Literal["gateway-runtime-profile-compatibility-matrix"]
    read_only: bool = True
    documentation_only: bool = True
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    auto_execution_supported: bool = False
    hardware_profile: GatewayRuntimeHardwareProfile
    profiles: list[GatewayRuntimeProfileCompatibilityProfile]


class GatewayRuntimeProfileRecommendation(BaseModel):
    model_target: str
    model_config_id: str | None = None
    compatibility: Literal["compatible", "borderline", "review_required", "unknown"]
    risk_level: Literal["low", "medium", "high", "unknown"]
    reason: str
    warnings: list[str] = Field(default_factory=list)


class GatewayRuntimeProfileRecommendations(BaseModel):
    default: GatewayRuntimeProfileRecommendation
    review: GatewayRuntimeProfileRecommendation
    fallback: GatewayRuntimeProfileRecommendation


class GatewayRuntimeProfileRecommendationSummaryResponse(BaseModel):
    status: Literal["ok", "review_required"]
    service: Literal["gateway-runtime-profile-recommendation-summary"]
    read_only: bool = True
    documentation_only: bool = True
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    auto_execution_supported: bool = False
    runbook: Literal["docs/gateway-runtime-switch-runbook.md"]
    hardware_profile: GatewayRuntimeHardwareProfile
    recommendations: GatewayRuntimeProfileRecommendations
    profiles: list[GatewayRuntimeProfileCompatibilityProfile]
    warnings: list[str] = Field(default_factory=list)
    next_steps: list[str] = Field(default_factory=list)


class GatewayRuntimeSwitchPlanRequest(BaseModel):
    message: str = Field(default="")
    intent: str | None = None
    target: str | None = None


class GatewayRuntimeSwitchPlanResponse(BaseModel):
    status: str
    intent: str
    apply_supported: bool = False
    auto_execution_supported: bool = False
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    requires_human_operator: bool = True
    target_model_id: str
    target_runtime_model_id: str | None = None
    current_active_model: str | None = None
    active_model_matches_target: bool
    risk_level: Literal["low", "medium", "high"]
    model_mapping_status: str
    guardrails: list[str] = Field(default_factory=list)
    preflight_checks: list[str] = Field(default_factory=list)
    manual_next_steps: list[str] = Field(default_factory=list)
    runbook: str
    runbook_status: Literal["manual_only"]
    runbook_required: bool = True
    verification_steps: list[str] = Field(default_factory=list)
    rollback_guidance: str
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


class GatewayChatProxyMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str = Field(min_length=1)


class GatewayChatProxyRequest(BaseModel):
    messages: list[GatewayChatProxyMessage] = Field(min_length=1)
    model: str | None = None
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=4096)
    stream: bool = False
    routing: Literal["auto", "off"] = "auto"
    memory: Literal["auto", "off"] = "auto"
    memory_limit: int = Field(default=3, ge=1, le=8)


class GatewayChatRouterMetadata(BaseModel):
    intent: str
    confidence: float
    selected_model_id: str
    selected_model_path: str | None = None
    active_model: str | None = None
    active_model_matches: bool
    active_model_mismatch_level: Literal["none", "info", "warning"]
    active_model_mismatch_reason: str
    routing_mode: Literal["advisory_only"]
    runtime_switch_supported: bool = False
    runtime_switch_attempted: bool = False
    model_mapping_status: str
    mode: Literal["advisory", "disabled"]
    reasons: list[str] = Field(default_factory=list)
    user_model_preference: str | None = None
    effective_runtime_model: str
    continue_safe: bool = True
    next_steps: list[str] = Field(default_factory=list)


class GatewayChatProxyResponse(BaseModel):
    status: str
    service: str
    model: str | None = None
    response: str | None = None
    router: GatewayChatRouterMetadata | None = None
    memory: dict[str, Any] | None = None
    raw: dict[str, Any] | None = None
    detail: str | None = None


class GatewayFeedbackRequest(BaseModel):
    request_id: str | None = Field(default=None, max_length=128)
    response_id: str | None = Field(default=None, max_length=128)
    source: Literal["continue", "gateway", "dashboard", "manual", "unknown"] = "unknown"
    rating: Literal["accepted", "rejected", "useful", "not_useful", "neutral"]
    reason: str | None = Field(default=None, max_length=1000)
    tags: list[str] = Field(default_factory=list, max_length=20)
    router_intent: str | None = Field(default=None, max_length=128)
    model: str | None = Field(default=None, max_length=256)

    @field_validator("tags")
    @classmethod
    def validate_tags(cls, tags: list[str]) -> list[str]:
        cleaned = []
        for tag in tags:
            if len(tag) > 64:
                raise ValueError("tags must be 64 characters or fewer")
            stripped = tag.strip()
            if stripped:
                cleaned.append(stripped)
        return cleaned


class GatewayFeedbackResponse(BaseModel):
    status: str
    service: str
    id: str | None = None
    path: str | None = None
    detail: str | None = None


class GatewayFeedbackStatusResponse(BaseModel):
    status: str
    service: str
    path: str
    exists: bool
    record_count: int
    latest_created_at: str | None = None
    detail: str | None = None


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


class GatewayCodeSelectedFile(BaseModel):
    path: str
    reason: str


class GatewayCodeContextRequest(BaseModel):
    task: str = Field(min_length=1)
    query: str | None = None
    paths: list[str] = Field(default_factory=list, max_length=20)
    max_files: int = Field(default=8, ge=1, le=20)
    max_chars: int = Field(default=20000, ge=1, le=50000)


class GatewayCodeContextResponse(BaseModel):
    status: str
    task: str
    query: str | None = None
    selected_files: list[GatewayCodeSelectedFile] = Field(default_factory=list)
    context: str
    truncated: bool


class GatewayCodeAskRequest(BaseModel):
    task: str = Field(min_length=1)
    query: str | None = None
    paths: list[str] = Field(default_factory=list, max_length=20)
    max_files: int = Field(default=8, ge=1, le=20)
    max_context_chars: int = Field(default=20000, ge=1, le=50000)
    temperature: float = Field(default=0.1, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=8192)
    use_memory: bool = False
    auto_route: bool = True


class GatewayCodeAskResponse(BaseModel):
    status: str
    content: str | None = None
    selected_files: list[GatewayCodeSelectedFile] = Field(default_factory=list)
    route: GatewayRouteMetadata | None = None
    memory: GatewayChatMemory | None = None
    model: str | None = None
    truncated: bool = False
    reason: str | None = None


class GatewayCodePatchPlanRequest(BaseModel):
    task: str = Field(min_length=1)
    query: str | None = None
    paths: list[str] = Field(default_factory=list, max_length=20)
    max_files: int = Field(default=8, ge=1, le=20)
    max_context_chars: int = Field(default=20000, ge=1, le=50000)
    temperature: float = Field(default=0.1, ge=0.0, le=2.0)
    max_tokens: int = Field(default=768, ge=1, le=8192)


class GatewayCodePatchPlanResponse(BaseModel):
    status: str
    summary: str | None = None
    affected_files: list[str] = Field(default_factory=list)
    proposed_steps: list[str] = Field(default_factory=list)
    risks: list[str] = Field(default_factory=list)
    tests_to_run: list[str] = Field(default_factory=list)
    selected_files: list[GatewayCodeSelectedFile] = Field(default_factory=list)
    route: GatewayRouteMetadata | None = None
    reason: str | None = None


class GatewayCodeDiffSuggestRequest(BaseModel):
    task: str = Field(min_length=1)
    query: str | None = None
    paths: list[str] = Field(default_factory=list, max_length=20)
    max_files: int = Field(default=8, ge=1, le=20)
    max_context_chars: int = Field(default=20000, ge=1, le=50000)
    temperature: float = Field(default=0.1, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1200, ge=1, le=8192)


class GatewayCodeDiffSuggestResponse(BaseModel):
    status: str
    diff: str | None = None
    explanation: str | None = None
    apply_supported: bool = False
    selected_files: list[GatewayCodeSelectedFile] = Field(default_factory=list)
    route: GatewayRouteMetadata | None = None
    reason: str | None = None


class GatewayMediaSafety(BaseModel):
    starts_services: bool = False
    stops_services: bool = False
    arbitrary_shell: bool = False
    real_generation_default: bool = False


class GatewayMediaHealthResponse(BaseModel):
    status: str
    service: str
    media_enabled: bool
    real_allowed: bool
    default_mode: str
    media_api_url: str
    prompt_interpreter_url: str
    media_api_reachable: bool
    prompt_interpreter_reachable: bool
    warnings: list[str] = Field(default_factory=list)
    safety: GatewayMediaSafety


class GatewayMediaPlanRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=4000)
    target_mode: Literal[
        "auto",
        "image",
        "video",
        "3d_suite",
        "3d_model",
        "rigging",
        "animation",
    ] = "auto"
    style: Literal["auto", "realistic", "technical", "cinematic", "product", "concept"] = "auto"


class GatewayMediaDryRunJobRequest(GatewayMediaPlanRequest):
    target_mode: Literal["auto", "image"] = "auto"


class GatewayMediaRealJobRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=4000)
    target_mode: Literal["image"] = "image"
    style: Literal["auto", "realistic", "technical", "cinematic", "product", "concept"] = "auto"
    confirm_real_generation: bool = False


class ReferenceBoardCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    board_id: str = Field(min_length=1, max_length=80)
    title: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=1000)


class GatewayMediaPlanResponse(BaseModel):
    status: str
    mode: str
    classification: dict[str, Any]
    job_spec: dict[str, Any]
    warnings: list[str] = Field(default_factory=list)
    next_steps: list[str] = Field(default_factory=list)


class GatewayMediaJobResponse(BaseModel):
    status: str
    mode: str | None = None
    plan: GatewayMediaPlanResponse | None = None
    media_api: dict[str, Any] | None = None
    reason: str | None = None
    safety: GatewayMediaSafety | None = None


class OpenAIChatMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class OpenAIChatCompletionRequest(BaseModel):
    model: str = "local-gateway"
    messages: list[OpenAIChatMessage] = Field(min_length=1)
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    max_tokens: int = Field(default=512, ge=1, le=8192)
    stream: bool = False
    tools: list[dict[str, Any]] | None = None
    tool_choice: str | dict[str, Any] | None = None
    parallel_tool_calls: bool | None = None
    response_format: dict[str, Any] | None = None
    stop: str | list[str] | None = None
    presence_penalty: float | None = None
    frequency_penalty: float | None = None
    top_p: float | None = None
    n: int | None = None
    user: str | None = None
    routing: Literal["auto", "off"] = "auto"
    memory: Literal["auto", "off"] = "auto"
    memory_limit: int = Field(default=3, ge=1, le=8)


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
    x_gateway_router: dict[str, Any] | None = None
    x_gateway_memory: dict[str, Any] | None = None
    x_gateway_compat: dict[str, Any] | None = None
