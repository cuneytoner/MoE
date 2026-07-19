import { useEffect, useMemo, useState } from "react";
import CheckCircleOutlineRoundedIcon from "@mui/icons-material/CheckCircleOutlineRounded";
import ErrorOutlineRoundedIcon from "@mui/icons-material/ErrorOutlineRounded";
import { Alert, Box, Card, CardContent, Stack, Typography } from "@mui/material";
import {
  addReferenceBoardItem,
  addThreeDReferenceBoardItem,
  createReferenceBoard,
  fetchAnimationOutputCards,
  fetchDashboard,
  fetchMemoryApprovalDashboard,
  fetchOutputCards,
  fetchReferenceBoard,
  fetchReferenceBoards,
  fetchRuntimeDashboard,
  fetchThreeDOutputCards,
  gatewayBaseUrl,
  removeReferenceBoardItem,
  updateReferenceBoardItem,
} from "./api";
import { GatesPanel } from "./components/GatesPanel";
import { LatestImagesPanel } from "./components/LatestImagesPanel";
import { ModeHintsPanel } from "./components/ModeHintsPanel";
import { MemoryApprovalPanel } from "./components/MemoryApprovalPanel";
import { AnimationOutputCards } from "./components/AnimationOutputCards";
import { OutputCards } from "./components/OutputCards";
import { ReferenceBoards } from "./components/ReferenceBoards";
import { RuntimeCards } from "./components/RuntimeCards";
import { SafeCommandsPanel } from "./components/SafeCommandsPanel";
import { ServicesPanel } from "./components/ServicesPanel";
import { SummaryCards } from "./components/SummaryCards";
import { SystemResourceCards } from "./components/SystemResourceCards";
import { ThreeDOutputCards } from "./components/ThreeDOutputCards";
import { WarningsPanel } from "./components/WarningsPanel";
import { DashboardLayout } from "./layout/DashboardLayout";
import type {
  DashboardModel,
  AnimationOutputCardsResponse,
  MemoryApprovalDashboardModel,
  OutputCard,
  OutputCardsResponse,
  ReferenceBoard,
  ReferenceBoardCreateRequest,
  ReferenceBoardUpdateItemRequest,
  ReferenceBoardsResponse,
  RuntimeDashboardModel,
  ThreeDOutputCard,
  ThreeDOutputCardsResponse,
} from "./types";

export function App() {
  const [dashboard, setDashboard] = useState<DashboardModel | null>(null);
  const [runtimeDashboard, setRuntimeDashboard] = useState<RuntimeDashboardModel | null>(null);
  const [memoryApprovalDashboard, setMemoryApprovalDashboard] = useState<MemoryApprovalDashboardModel | null>(null);
  const [outputCards, setOutputCards] = useState<OutputCardsResponse | null>(null);
  const [threeDOutputCards, setThreeDOutputCards] = useState<ThreeDOutputCardsResponse | null>(null);
  const [animationOutputCards, setAnimationOutputCards] = useState<AnimationOutputCardsResponse | null>(null);
  const [referenceBoards, setReferenceBoards] = useState<ReferenceBoardsResponse | null>(null);
  const [activeReferenceBoard, setActiveReferenceBoard] = useState<ReferenceBoard | null>(null);
  const [activeReferenceBoardId, setActiveReferenceBoardId] = useState("");
  const [error, setError] = useState("");
  const [runtimeError, setRuntimeError] = useState("");
  const [memoryApprovalError, setMemoryApprovalError] = useState("");
  const [outputCardsError, setOutputCardsError] = useState("");
  const [threeDOutputCardsError, setThreeDOutputCardsError] = useState("");
  const [animationOutputCardsError, setAnimationOutputCardsError] = useState("");
  const [referenceBoardError, setReferenceBoardError] = useState("");
  const [referenceBoardActionMessage, setReferenceBoardActionMessage] = useState("");
  const [addingBoardCardId, setAddingBoardCardId] = useState("");
  const [addingThreeDBoardCardId, setAddingThreeDBoardCardId] = useState("");
  const [loading, setLoading] = useState(false);
  const [referenceBoardLoading, setReferenceBoardLoading] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<string>("never");

  async function refresh() {
    setLoading(true);
    setError("");
    setRuntimeError("");
    setMemoryApprovalError("");
    setOutputCardsError("");
    setThreeDOutputCardsError("");
    setAnimationOutputCardsError("");
    setReferenceBoardError("");
    try {
      const next = await fetchDashboard();
      setDashboard(next);
      setLastRefresh(new Date().toLocaleString());
    } catch (err) {
      setError(err instanceof Error ? err.message : "unknown error");
    }
    try {
      const nextRuntime = await fetchRuntimeDashboard();
      setRuntimeDashboard(nextRuntime);
    } catch (err) {
      setRuntimeError(err instanceof Error ? err.message : "unknown runtime error");
    }
    try {
      const nextMemoryApproval = await fetchMemoryApprovalDashboard();
      setMemoryApprovalDashboard(nextMemoryApproval);
    } catch (err) {
      setMemoryApprovalError(err instanceof Error ? err.message : "unknown memory approval error");
    }
    try {
      const nextOutputCards = await fetchOutputCards();
      setOutputCards(nextOutputCards);
    } catch (err) {
      setOutputCardsError(err instanceof Error ? err.message : "unknown output cards error");
    }
    try {
      const nextThreeDOutputCards = await fetchThreeDOutputCards();
      setThreeDOutputCards(nextThreeDOutputCards);
    } catch (err) {
      setThreeDOutputCardsError(err instanceof Error ? err.message : "unknown 3D output cards error");
    }
    try {
      const nextAnimationOutputCards = await fetchAnimationOutputCards();
      setAnimationOutputCards(nextAnimationOutputCards);
    } catch (err) {
      setAnimationOutputCards(null);
      setAnimationOutputCardsError(err instanceof Error ? err.message : "Animation output cards unavailable");
    }
    try {
      const nextReferenceBoards = await fetchReferenceBoards();
      setReferenceBoards(nextReferenceBoards);
      if (activeReferenceBoardId) {
        const nextActiveBoard = await fetchReferenceBoard(activeReferenceBoardId);
        setActiveReferenceBoard(nextActiveBoard.board);
      }
    } catch (err) {
      setReferenceBoardError(referenceBoardUiError("Board load failed.", err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void refresh();
  }, []);

  const safetyUnsafe = useMemo(() => {
    if (!dashboard) {
      return false;
    }
    return (
      dashboard.safety.read_only !== true ||
      dashboard.safety.starts_services !== false ||
      dashboard.safety.stops_services !== false ||
      dashboard.safety.real_generation_trigger !== false ||
      dashboard.safety.arbitrary_shell !== false
    );
  }, [dashboard]);

  async function refreshReferenceBoards(boardId = activeReferenceBoardId) {
    setReferenceBoardLoading(true);
    setReferenceBoardError("");
    try {
      const nextReferenceBoards = await fetchReferenceBoards();
      setReferenceBoards(nextReferenceBoards);
      if (boardId) {
        const nextActiveBoard = await fetchReferenceBoard(boardId);
        setActiveReferenceBoard(nextActiveBoard.board);
      }
    } catch (err) {
      setReferenceBoardError(err instanceof Error ? err.message : "unknown reference board error");
    } finally {
      setReferenceBoardLoading(false);
    }
  }

  async function handleCreateReferenceBoard(request: ReferenceBoardCreateRequest) {
    setReferenceBoardActionMessage("");
    setReferenceBoardLoading(true);
    setReferenceBoardError("");
    try {
      const created = await createReferenceBoard(request);
      setActiveReferenceBoardId(created.board.board_id);
      setActiveReferenceBoard(created.board);
      const nextReferenceBoards = await fetchReferenceBoards();
      setReferenceBoards(nextReferenceBoards);
      setReferenceBoardActionMessage("Reference board created.");
    } catch (err) {
      setReferenceBoardError(referenceBoardUiError("Create board failed.", err));
    } finally {
      setReferenceBoardLoading(false);
    }
  }

  async function handleSelectReferenceBoard(boardId: string) {
    setReferenceBoardActionMessage("");
    setReferenceBoardLoading(true);
    setReferenceBoardError("");
    try {
      const nextActiveBoard = await fetchReferenceBoard(boardId);
      setActiveReferenceBoardId(boardId);
      setActiveReferenceBoard(nextActiveBoard.board);
    } catch (err) {
      setReferenceBoardError(referenceBoardUiError("Board load failed.", err));
    } finally {
      setReferenceBoardLoading(false);
    }
  }

  async function handleAddCardToBoard(card: OutputCard) {
    if (!activeReferenceBoardId) {
      return;
    }
    setAddingBoardCardId(card.id);
    setReferenceBoardActionMessage("");
    setReferenceBoardError("");
    try {
      const updated = await addReferenceBoardItem(activeReferenceBoardId, {
        card_id: card.id,
        selected_reason: "Selected from dashboard output cards.",
        tags: card.tags,
      });
      setActiveReferenceBoard(updated.board);
      await refreshReferenceBoards(activeReferenceBoardId);
      setReferenceBoardActionMessage("Added to board.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "unknown error";
      if (message.includes("already selected")) {
        setReferenceBoardActionMessage("Already in board.");
      } else {
        setReferenceBoardError(referenceBoardUiError("Add item failed.", err));
      }
    } finally {
      setAddingBoardCardId("");
    }
  }

  async function handleAddThreeDCardToBoard(card: ThreeDOutputCard) {
    if (!activeReferenceBoardId) {
      return;
    }
    setAddingThreeDBoardCardId(card.id);
    setReferenceBoardActionMessage("");
    setReferenceBoardError("");
    try {
      const safeTags = ["3d", card.asset_category, ...card.formats]
        .map((tag) => tag.trim())
        .filter((tag, index, tags) => tag !== "" && tag.length <= 40 && /^[A-Za-z0-9 _-]+$/.test(tag) && tags.indexOf(tag) === index)
        .slice(0, 12);
      const updated = await addThreeDReferenceBoardItem(activeReferenceBoardId, {
        card_id: card.id,
        selected_reason: "Selected from dashboard 3D output cards.",
        tags: safeTags,
      });
      setActiveReferenceBoard(updated.board);
      await refreshReferenceBoards(activeReferenceBoardId);
      setReferenceBoardActionMessage("Added 3D reference to board.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "unknown error";
      if (message.includes("already selected") || message.includes("already")) {
        setReferenceBoardActionMessage("Already in board.");
      } else {
        setReferenceBoardError(referenceBoardUiError("Add 3D item failed.", err));
      }
    } finally {
      setAddingThreeDBoardCardId("");
    }
  }

  async function handleRemoveBoardItem(itemId: string) {
    if (!activeReferenceBoardId) {
      return;
    }
    setReferenceBoardActionMessage("");
    setReferenceBoardError("");
    setReferenceBoardLoading(true);
    try {
      const updated = await removeReferenceBoardItem(activeReferenceBoardId, itemId);
      setActiveReferenceBoard(updated.board);
      await refreshReferenceBoards(activeReferenceBoardId);
      setReferenceBoardActionMessage("Removed from board.");
    } catch (err) {
      setReferenceBoardError(referenceBoardUiError("Remove item failed.", err));
    } finally {
      setReferenceBoardLoading(false);
    }
  }

  async function handleUpdateBoardItem(itemId: string, request: ReferenceBoardUpdateItemRequest) {
    if (!activeReferenceBoardId) {
      return;
    }
    setReferenceBoardActionMessage("");
    setReferenceBoardError("");
    setReferenceBoardLoading(true);
    try {
      const updated = await updateReferenceBoardItem(activeReferenceBoardId, itemId, request);
      setActiveReferenceBoard(updated.board);
      await refreshReferenceBoards(activeReferenceBoardId);
      setReferenceBoardActionMessage("Board note updated.");
    } catch (err) {
      const message = referenceBoardUiError("Save note failed.", err);
      setReferenceBoardError(message);
      throw new Error(message);
    } finally {
      setReferenceBoardLoading(false);
    }
  }

  return (
    <DashboardLayout loading={loading} lastRefresh={lastRefresh} onRefresh={() => void refresh()}>
      {error ? (
        <Alert icon={<ErrorOutlineRoundedIcon />} severity="error" variant="outlined">
          Gateway unavailable from {gatewayBaseUrl()}: {error}
        </Alert>
      ) : null}

      <Alert
        icon={safetyUnsafe ? <ErrorOutlineRoundedIcon /> : <CheckCircleOutlineRoundedIcon />}
        severity={safetyUnsafe ? "error" : "success"}
        variant="filled"
      >
        <strong>Safety:</strong>{" "}
        {dashboard
          ? safetyUnsafe
            ? "Unsafe dashboard flags detected. Do not use this UI for operations."
            : "Read-only. No service control, shell execution, suspend, or real generation trigger."
          : "Waiting for Gateway dashboard data."}
      </Alert>

      <SummaryCards dashboard={dashboard} />
      <RuntimeCards error={runtimeError} runtime={runtimeDashboard} />
      {runtimeDashboard?.system ? (
        <Stack id="system-resources" spacing={2}>
          <Typography variant="h6">System Resources</Typography>
          <Box sx={{ display: "grid", gap: 2, gridTemplateColumns: { xs: "1fr", lg: "repeat(3, minmax(0, 1fr))" } }}>
            <SystemResourceCards system={runtimeDashboard.system} />
          </Box>
        </Stack>
      ) : null}
      <MemoryApprovalPanel error={memoryApprovalError} memoryApproval={memoryApprovalDashboard} />
      <ThreeDOutputCards
        activeBoardId={activeReferenceBoardId}
        addingCardId={addingThreeDBoardCardId}
        cardsResponse={threeDOutputCards}
        error={threeDOutputCardsError}
        loading={loading}
        onAddToBoard={(card) => void handleAddThreeDCardToBoard(card)}
      />
      <AnimationOutputCards cardsResponse={animationOutputCards} error={animationOutputCardsError} loading={loading} />

      {dashboard ? (
        <>
          <ServicesPanel services={dashboard.services} />
          <GatesPanel gates={dashboard.gates} />
          <LatestImagesPanel images={dashboard.latest_images} />
          <ReferenceBoards
            actionMessage={referenceBoardActionMessage}
            activeBoard={activeReferenceBoard}
            boards={referenceBoards?.boards ?? []}
            error={referenceBoardError}
            loading={loading || referenceBoardLoading}
            onCreateBoard={handleCreateReferenceBoard}
            onRemoveBoardItem={handleRemoveBoardItem}
            onSelectBoard={handleSelectReferenceBoard}
            onUpdateBoardItem={handleUpdateBoardItem}
          />
          <OutputCards
            activeBoardId={activeReferenceBoardId}
            addingCardId={addingBoardCardId}
            boardActionMessage={referenceBoardActionMessage}
            cards={outputCards?.cards ?? []}
            error={outputCardsError}
            loading={loading}
            onAddToBoard={(card) => void handleAddCardToBoard(card)}
          />
          <Box sx={{ display: "grid", gap: 3, gridTemplateColumns: { xs: "1fr", xl: "1.1fr 0.9fr" } }}>
            <SafeCommandsPanel commands={dashboard.safe_commands} />
            <ModeHintsPanel hints={dashboard.mode_hints} />
          </Box>
          <Card>
            <CardContent>
              <Typography gutterBottom variant="h6">
                PC1 / PC2 Roles
              </Typography>
              <Box sx={{ display: "grid", gap: 2, gridTemplateColumns: { xs: "1fr", md: "repeat(2, 1fr)" } }}>
                <RoleCard
                  label="PC-1"
                  text="Main workstation, Gateway, coding model runtime, ComfyUI, Media API, Media Worker, and GPU generation host."
                />
                <RoleCard
                  label="PC-2"
                  text="Helper node for Prompt Interpreter, learning, research, feedback, reports, and future background jobs."
                />
              </Box>
            </CardContent>
          </Card>
          <WarningsPanel
            warnings={[
              ...dashboard.warnings,
              ...(runtimeDashboard?.warnings ?? []),
              ...(memoryApprovalDashboard?.warnings ?? []),
            ]}
          />
        </>
      ) : null}

      <Typography align="center" color="text.secondary" variant="body2">
        M36 Animation Pipeline Dashboard. Read-only. No generation or service control.
      </Typography>
    </DashboardLayout>
  );
}

function RoleCard({ label, text }: { label: string; text: string }) {
  return (
    <Card variant="outlined">
      <CardContent>
        <Stack spacing={1}>
          <Typography fontWeight={800}>{label}</Typography>
          <Typography color="text.secondary" variant="body2">
            {text}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function referenceBoardUiError(prefix: string, err: unknown): string {
  const detail = err instanceof Error ? err.message : "Unknown error.";
  return `${prefix} ${detail}`;
}
