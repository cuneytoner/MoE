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
