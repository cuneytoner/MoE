import { useEffect, useMemo, useState } from "react";
import CheckCircleOutlineRoundedIcon from "@mui/icons-material/CheckCircleOutlineRounded";
import ErrorOutlineRoundedIcon from "@mui/icons-material/ErrorOutlineRounded";
import { Alert, Box, Card, CardContent, Stack, Typography } from "@mui/material";
import { fetchDashboard, fetchMemoryApprovalDashboard, fetchOutputCards, fetchRuntimeDashboard, gatewayBaseUrl } from "./api";
import { GatesPanel } from "./components/GatesPanel";
import { LatestImagesPanel } from "./components/LatestImagesPanel";
import { ModeHintsPanel } from "./components/ModeHintsPanel";
import { MemoryApprovalPanel } from "./components/MemoryApprovalPanel";
import { OutputCards } from "./components/OutputCards";
import { RuntimeCards } from "./components/RuntimeCards";
import { SafeCommandsPanel } from "./components/SafeCommandsPanel";
import { ServicesPanel } from "./components/ServicesPanel";
import { SummaryCards } from "./components/SummaryCards";
import { SystemResourceCards } from "./components/SystemResourceCards";
import { WarningsPanel } from "./components/WarningsPanel";
import { DashboardLayout } from "./layout/DashboardLayout";
import type { DashboardModel, MemoryApprovalDashboardModel, OutputCardsResponse, RuntimeDashboardModel } from "./types";

export function App() {
  const [dashboard, setDashboard] = useState<DashboardModel | null>(null);
  const [runtimeDashboard, setRuntimeDashboard] = useState<RuntimeDashboardModel | null>(null);
  const [memoryApprovalDashboard, setMemoryApprovalDashboard] = useState<MemoryApprovalDashboardModel | null>(null);
  const [outputCards, setOutputCards] = useState<OutputCardsResponse | null>(null);
  const [error, setError] = useState("");
  const [runtimeError, setRuntimeError] = useState("");
  const [memoryApprovalError, setMemoryApprovalError] = useState("");
  const [outputCardsError, setOutputCardsError] = useState("");
  const [loading, setLoading] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<string>("never");

  async function refresh() {
    setLoading(true);
    setError("");
    setRuntimeError("");
    setMemoryApprovalError("");
    setOutputCardsError("");
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

      {dashboard ? (
        <>
          <ServicesPanel services={dashboard.services} />
          <GatesPanel gates={dashboard.gates} />
          <LatestImagesPanel images={dashboard.latest_images} />
          <OutputCards cards={outputCards?.cards ?? []} error={outputCardsError} loading={loading} />
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
        M29.8 Memory Approval Dashboard. Read-only. No service control.
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
