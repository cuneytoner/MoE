import type {
  DashboardModel,
  MemoryApprovalDashboardModel,
  OutputCardMetadataResponse,
  OutputCardsResponse,
  ReferenceBoardAddItemRequest,
  ReferenceBoardCreateRequest,
  ReferenceBoardResponse,
  ReferenceBoardUpdateItemRequest,
  ReferenceBoardsResponse,
  RuntimeDashboardModel,
} from "./types";

const gatewayUrl = import.meta.env.VITE_GATEWAY_API_URL ?? "http://127.0.0.1:8100";

type GatewayErrorPayload = {
  status?: string;
  error?: string;
  detail?: string;
};

async function gatewayErrorMessage(response: Response, fallback: string): Promise<string> {
  try {
    const payload = (await response.json()) as GatewayErrorPayload;
    if (typeof payload.detail === "string" && payload.detail.trim() !== "") {
      return payload.detail;
    }
    if (typeof payload.error === "string" && payload.error.trim() !== "") {
      return payload.error;
    }
  } catch {
    // Keep UI errors concise and safe when Gateway does not return JSON.
  }
  return `${fallback} returned HTTP ${response.status}`;
}

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
    throw new Error(await gatewayErrorMessage(response, "Gateway reference boards"));
  }
  return response.json();
}

export async function fetchReferenceBoard(boardId: string): Promise<ReferenceBoardResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}`);
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board"));
  }
  return response.json();
}

export async function fetchReferenceBoardJsonExport(boardId: string): Promise<unknown> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/export/json`);
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board JSON export"));
  }
  return response.json();
}

export async function fetchReferenceBoardMarkdownExport(boardId: string): Promise<string> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/export/markdown`);
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board Markdown export"));
  }
  return response.text();
}

export function referenceBoardJsonDownloadUrl(boardId: string): string {
  return `${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/download/json`;
}

export function referenceBoardMarkdownDownloadUrl(boardId: string): string {
  return `${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/download/markdown`;
}

export async function createReferenceBoard(request: ReferenceBoardCreateRequest): Promise<ReferenceBoardResponse> {
  const response = await fetch(`${gatewayUrl}/gateway/media/reference-boards`, {
    body: JSON.stringify(request),
    headers: { "Content-Type": "application/json" },
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board create"));
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
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board item add"));
  }
  return response.json();
}

export async function removeReferenceBoardItem(boardId: string, itemId: string): Promise<ReferenceBoardResponse> {
  const response = await fetch(
    `${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/items/${encodeURIComponent(itemId)}`,
    { method: "DELETE" },
  );
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board item remove"));
  }
  return response.json();
}

export async function updateReferenceBoardItem(
  boardId: string,
  itemId: string,
  request: ReferenceBoardUpdateItemRequest,
): Promise<ReferenceBoardResponse> {
  const response = await fetch(
    `${gatewayUrl}/gateway/media/reference-boards/${encodeURIComponent(boardId)}/items/${encodeURIComponent(itemId)}`,
    {
      body: JSON.stringify(request),
      headers: { "Content-Type": "application/json" },
      method: "PATCH",
    },
  );
  if (!response.ok) {
    throw new Error(await gatewayErrorMessage(response, "Gateway reference board item update"));
  }
  return response.json();
}

export function gatewayBaseUrl(): string {
  return gatewayUrl;
}
