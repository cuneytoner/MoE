import type { DashboardModel, RuntimeDashboardModel } from "./types";

const gatewayUrl = import.meta.env.VITE_GATEWAY_API_URL ?? "http://127.0.0.1:8100";

export async function fetchDashboard(): Promise<DashboardModel> {
  const response = await fetch(`${gatewayUrl}/gateway/media/dashboard`);
  if (!response.ok) {
    throw new Error(`Gateway returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function fetchRuntimeDashboard(): Promise<RuntimeDashboardModel> {
  const response = await fetch(`${gatewayUrl}/gateway/runtime/dashboard`);
  if (!response.ok) {
    throw new Error(`Gateway runtime dashboard returned HTTP ${response.status}`);
  }
  return response.json();
}

export function gatewayBaseUrl(): string {
  return gatewayUrl;
}
