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
