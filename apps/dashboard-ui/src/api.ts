import type {
  DashboardModel,
  MemoryApprovalDashboardModel,
  OutputCardMetadataResponse,
  OutputCardsResponse,
  ReferenceBoardAddItemRequest,
  ReferenceBoardCreateRequest,
  ReferenceBoardResponse,
  ReferenceBoardsResponse,
  RuntimeDashboardModel,
} from "./types";

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

export async function fetchOutputCardMetadata(cardId: string): Promise<OutputCardMetadataResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/output-card-metadata/${encodeURIComponent(cardId)}`);
  if (!response.ok) {
    throw new Error(`Gateway output card metadata returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function fetchReferenceBoards(): Promise<ReferenceBoardsResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards`);
  if (!response.ok) {
    throw new Error(`Gateway reference boards returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function fetchReferenceBoard(boardId: string): Promise<ReferenceBoardResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}`);
  if (!response.ok) {
    throw new Error(`Gateway reference board returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function createReferenceBoard(request: ReferenceBoardCreateRequest): Promise<ReferenceBoardResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards`, {
    body: JSON.stringify(request),
    headers: { "Content-Type": "application/json" },
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(`Gateway reference board create returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function addReferenceBoardItem(
  boardId: string,
  request: ReferenceBoardAddItemRequest,
): Promise<ReferenceBoardResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/items`, {
    body: JSON.stringify(request),
    headers: { "Content-Type": "application/json" },
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(`Gateway reference board item add returned HTTP ${response.status}`);
  }
  return response.json();
}

export async function removeReferenceBoardItem(boardId: string, itemId: string): Promise<ReferenceBoardResponse> {
  const response = await fetch(
    `${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/items/${encodeURIComponent(itemId)}`,
    { method: "DELETE" },
  );
  if (!response.ok) {
    throw new Error(`Gateway reference board item remove returned HTTP ${response.status}`);
  }
  return response.json();
}

export function gatewayBaseUrl(): string {
  return gatewayUrl;
}
