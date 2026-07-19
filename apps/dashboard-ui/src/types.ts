export type SafetyModel = {
  read_only: boolean;
  starts_services: boolean;
  stops_services: boolean;
  real_generation_trigger: boolean;
  arbitrary_shell: boolean;
};

export type ServiceStatus = {
  status: string;
  service: string;
  url: string;
  reachable?: boolean;
  http_status?: number;
  detail?: string;
};

export type ImageInfo = {
  path: string;
  name: string;
  modified: string;
  size_bytes: number;
};

export type DashboardModel = {
  status: string;
  service: string;
  safety: SafetyModel;
  services: Record<string, ServiceStatus>;
  gates: Record<string, boolean>;
  latest_images: ImageInfo[];
  mode_hints: Record<string, string>;
  safe_commands: Record<string, string[]>;
  warnings: string[];
};

export type GpuStatus = {
  available: boolean;
  name: string;
  memory_total_mb: number;
  memory_used_mb: number;
  memory_free_mb: number;
  utilization_gpu_percent: number;
  detail: string;
};

export type LlamaServerStatus = {
  reachable: boolean;
  url: string;
  model?: string | null;
  detail?: string;
  status?: string;
};

export type ComfyUiStatus = ServiceStatus & {
  bridge_required: boolean;
};

export type RuntimeJobSummary = {
  job_id?: string | null;
  state?: string | null;
  mode?: string | null;
  job_type?: string | null;
  job_path?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  modified?: string | null;
};

export type ImageLifecycle = {
  dry_run_available: boolean;
  real_generation_locked: boolean;
  comfyui_ready: boolean;
  media_api_ready: boolean;
  media_worker_ready: boolean;
  prompt_interpreter_ready: boolean;
  recommended_mode: string;
  next_safe_step: string;
};

export type SystemMemory = {
  total_mb: number;
  used_mb: number;
  free_mb: number;
  available_mb: number;
  used_percent: number;
};

export type SystemCpu = {
  load_1m: number;
  load_5m: number;
  load_15m: number;
  cpu_count: number;
};

export type SystemDisk = {
  path: string;
  total_gb: number;
  used_gb: number;
  free_gb: number;
  used_percent: number;
};

export type SystemUptime = {
  seconds: number;
  human: string;
};

export type SystemStatus = {
  pc1: {
    memory: SystemMemory;
    cpu: SystemCpu;
    disk: SystemDisk;
    uptime: SystemUptime;
  };
  pc2: {
    status: string;
    service?: string;
    read_only?: boolean;
    host_role?: string;
    detail?: string;
    memory?: SystemMemory;
    cpu?: SystemCpu;
    disk?: SystemDisk;
    uptime?: SystemUptime;
  };
  docker: {
    status: string;
    service?: string;
    read_only?: boolean;
    generated_at?: string;
    source?: string;
    detail?: string;
    services: Array<{
      name?: string;
      status?: string;
      health?: string;
      ports?: string;
      image?: string;
    }>;
    summary?: {
      total: number;
      running: number;
      healthy: number;
      unhealthy: number;
      missing: number;
    };
  };
};

export type RuntimeProfileRecommendation = {
  model_target: string;
  model_config_id?: string | null;
  compatibility: string;
  risk_level: string;
  reason: string;
  warnings: string[];
};

export type RuntimeProfileSummary = {
  status: string;
  hardware_profile: {
    name: string;
    gpu: string;
    vram_gb: number;
    ram_gb: number;
    cpu: string;
  };
  recommendations: {
    default: RuntimeProfileRecommendation;
    review: RuntimeProfileRecommendation;
    fallback: RuntimeProfileRecommendation;
  };
  warnings: string[];
  next_steps: string[];
  source_endpoint: string;
  read_only: boolean;
  documentation_only: boolean;
  runtime_switch_supported: boolean;
  runtime_switch_attempted: boolean;
  auto_execution_supported: boolean;
};

export type RuntimeDashboardModel = {
  status: string;
  service: string;
  safety: SafetyModel;
  pc1: {
    role: string;
    hostname: string;
    gateway_api: ServiceStatus;
    llama_server: LlamaServerStatus;
    gpu: GpuStatus;
    comfyui: ComfyUiStatus;
  };
  pc2: {
    role: string;
    host: string;
    prompt_interpreter: ServiceStatus;
    nightly_learning: ServiceStatus;
    research_ingestion: ServiceStatus;
    feedback_worker: ServiceStatus;
  };
  media_jobs: {
    latest_job: RuntimeJobSummary | null;
    latest_jobs: RuntimeJobSummary[];
    jobs_dir: string;
    total_visible_jobs: number;
  };
  image_lifecycle: ImageLifecycle;
  runtime_profile_summary?: RuntimeProfileSummary;
  system: SystemStatus;
  warnings: string[];
};

export type MemoryApprovalReportMetadata = {
  path: string;
  exists: boolean;
  valid: boolean;
  modified_at?: string | null;
  size_bytes?: number | null;
};

export type MemoryApprovalCandidate = {
  id: string;
  category: string;
  risk: string;
  current_status: string;
  duplicate_group_id?: string | null;
  title: string;
  review_hint: string;
};

export type MemoryApprovalDuplicateGroup = {
  group_id: string;
  category: string;
  normalized_title: string;
  count: number;
  candidate_ids: string[];
  recommended_action: string;
};

export type MemoryApprovalDashboardModel = {
  service: string;
  generated_at: string;
  read_only: boolean;
  apply_supported: boolean;
  approval_supported: boolean;
  memory_write_supported: boolean;
  human_review_required: boolean;
  reports: Record<string, MemoryApprovalReportMetadata>;
  summary: {
    total_candidates: number;
    approved_count: number;
    blocked_count: number;
    duplicate_group_count: number;
    duplicate_candidate_count: number;
    dry_run_attempt_count: number;
    stored_count: number;
    failed_count: number;
    skipped_count: number;
  };
  candidates: MemoryApprovalCandidate[];
  duplicates: MemoryApprovalDuplicateGroup[];
  approval: {
    real_approval_file_exists: boolean;
    example_approval_file_exists: boolean;
    approval_file_path: string;
    example_approval_file_path: string;
    approved_candidate_ids_count: number;
  };
  apply_log: {
    log_exists: boolean;
    summary_exists: boolean;
    total_attempts: number;
    stored_count: number;
    failed_count: number;
    skipped_count: number;
    dry_run_count: number;
    latest_attempt_at?: string | null;
  };
  e2e: {
    report_exists: boolean;
    e2e_status?: string | null;
    dry_run_only?: boolean | null;
    apply_used?: boolean | null;
    test_approval_fixture_used?: boolean | null;
    test_approval_fixture_removed?: boolean | null;
  };
  warnings: string[];
  safety_boundaries: string[];
};

export type OutputCard = {
  id: string;
  type: string;
  name: string;
  path: string;
  relative_runtime_path: string;
  modified: string;
  size_bytes: number;
  preview_available: boolean;
  source: string;
  tags: string[];
  safety_label: string;
  metadata_available: boolean;
  metadata_path: string | null;
  notes: string | null;
};

export type OutputCardsResponse = {
  status: string;
  service: string;
  safety: SafetyModel;
  allowlisted_roots: string[];
  max_cards: number;
  cards: OutputCard[];
};

export type OutputCardMetadataResponse = {
  status: string;
  service: string;
  card_id: string;
  metadata_available: boolean;
  metadata: Record<string, unknown>;
};

export type ThreeDArtifactVerification = {
  metadata_valid: boolean;
  artifacts_valid: boolean;
  valid: boolean;
  declared_count: number;
  existing_count: number;
  missing_count: number;
  error_count: number;
  errors: string[];
};

export type ThreeDRelativeRuntimePaths = {
  blend: string | null;
  glb: string | null;
  obj: string | null;
  preview: string | null;
  metadata: string | null;
  report: string | null;
};

export type ThreeDOutputCard = {
  id: string;
  type: "3d_model";
  asset_name: string;
  asset_category: string;
  created_at: string;
  formats: string[];
  preview_available: boolean;
  metadata_path: string;
  relative_runtime_paths: ThreeDRelativeRuntimePaths;
  safety_label: string;
  structural_certification: false;
  operator_review_required: true;
  generation_mode: string | null;
  verification: ThreeDArtifactVerification;
};

export type ThreeDOutputCardsResponse = {
  status: string;
  service: string;
  runtime_scope: string;
  metadata_dir_available: boolean;
  card_count: number;
  invalid_count: number;
  cards: ThreeDOutputCard[];
  warnings: string[];
  safety_flags: {
    read_only: boolean;
    generation_triggered: boolean;
    runtime_assets_written: boolean;
    source_assets_modified: boolean;
    shell_execution: boolean;
  };
};

export type AnimationTimelineSummary = {
  fps: number;
  start_frame: number;
  end_frame: number;
  frame_count?: number | null;
  total_frames?: number | null;
  duration_seconds: number;
};

export type AnimationOutputSummary = {
  track_count: number;
  keyframe_count: number;
  segment_count: number;
  operation_count: number;
  target_types: string[];
  target_ids: string[];
  properties: string[];
  interpolations: string[];
};

export type AnimationPreviewSummary = {
  available: boolean;
  preview_id: string | null;
  format: string | null;
  frame_count: number | null;
  width: number | null;
  height: number | null;
  relative_directory: string | null;
  first_frame_relative_path: string | null;
  total_output_bytes: number | null;
};

export type AnimationRelativeRuntimePaths = {
  metadata: string | null;
  declared_video_preview: string | null;
  preview_frames: string | null;
  report: string | null;
};

export type AnimationVerificationSummary = {
  metadata_valid: boolean;
  provenance_checked: boolean;
  preview_report_valid: boolean;
  runtime_preview_verified: boolean;
  valid: boolean;
  error_count: number;
  warning_count: number;
};

export type AnimationOutputCard = {
  id: string;
  type: "animation";
  animation_id: string;
  title: string;
  created_at: string;
  source_kind: string;
  generation_mode: string | null;
  timeline: AnimationTimelineSummary;
  summary: AnimationOutputSummary;
  preview: AnimationPreviewSummary;
  relative_runtime_paths: AnimationRelativeRuntimePaths;
  verification: AnimationVerificationSummary;
  visual_reference_only: boolean;
  structural_certification: false;
  operator_review_required: true;
};

export type AnimationOutputCardsResponse = {
  status: string;
  service: string;
  runtime_scope: string;
  metadata_dir_available: boolean;
  reports_dir_available: boolean;
  card_count: number;
  invalid_count: number;
  preview_report_count: number;
  verified_preview_count: number;
  cards: AnimationOutputCard[];
  warnings: string[];
  safety_flags: {
    read_only: boolean;
    generation_triggered: boolean;
    animation_execution_attempted: boolean;
    preview_render_attempted: boolean;
    runtime_assets_written: boolean;
    runtime_assets_modified: boolean;
    runtime_assets_deleted: boolean;
    source_assets_modified: boolean;
    external_process_started: boolean;
    shell_execution: boolean;
  };
};

export type ReferenceBoardSummary = {
  board_id: string;
  title: string;
  description: string | null;
  created_at: string;
  updated_at: string;
  safety_label: string;
  item_count: number;
};

export type ReferenceBoardItem = {
  item_id: string;
  card_id: string;
  asset_type: string;
  name: string;
  relative_runtime_path: string;
  metadata_path: string | null;
  selected_reason: string | null;
  tags: string[];
  safety_label: string;
  added_at: string;
};

export type ReferenceBoard = {
  schema_version: string;
  board_id: string;
  title: string;
  description: string | null;
  created_at: string;
  updated_at: string;
  safety_label: string;
  items: ReferenceBoardItem[];
};

export type ReferenceBoardsResponse = {
  status: string;
  service: string;
  safety: SafetyModel;
  root: string;
  boards: ReferenceBoardSummary[];
};

export type ReferenceBoardResponse = {
  status: string;
  service: string;
  board: ReferenceBoard;
};

export type ReferenceBoardCreateRequest = {
  board_id: string;
  title: string;
  description?: string | null;
};

export type ReferenceBoardAddItemRequest = {
  card_id: string;
  selected_reason?: string | null;
  tags?: string[] | null;
};

export type ReferenceBoardAddThreeDItemRequest = {
  card_id: string;
  selected_reason?: string | null;
  tags?: string[] | null;
};

export type ReferenceBoardAddAnimationItemRequest = {
  card_id: string;
  selected_reason?: string | null;
  tags?: string[] | null;
};

export type ReferenceBoardUpdateItemRequest = {
  selected_reason?: string | null;
  tags?: string[] | null;
};
