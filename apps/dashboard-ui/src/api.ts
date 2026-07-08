import type { DashboardModel, MemoryApprovalDashboardModel, OutputCardsResponse, RuntimeDashboardModel } from "./types";

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

export async function fetchMemoryApprovalDashboard(): Promise<MemoryApprovalDashboardModel> {
  const response = await fetch(`${gatewayUrl}/gateway/memory-approval/dashboard`);
  if (!response.ok) {
    throw new Error(`Gateway memory approval dashboard returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function fetchOutputCards(): Promise<OutputCardsResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/output-cards`);
  if (!response.ok) {
    throw new Error(`Gateway output cards returned HTTP ${response.status}`);
  }
  return response.json();
}

export function gatewayBaseUrl(): string {
  return gatewayUrl;
}
