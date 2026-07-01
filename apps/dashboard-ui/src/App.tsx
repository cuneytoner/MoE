import { useEffect, useMemo, useState } from "react";
import CheckCircleOutlineRoundedIcon from "@mui/icons-material/CheckCircleOutlineRounded";
import ErrorOutlineRoundedIcon from "@mui/icons-material/ErrorOutlineRounded";
import { Alert, Box, Card, CardContent, Stack, Typography } from "@mui/material";
import { fetchDashboard, gatewayBaseUrl } from "./api";
import { GatesPanel } from "./components/GatesPanel";
import { LatestImagesPanel } from "./components/LatestImagesPanel";
import { ModeHintsPanel } from "./components/ModeHintsPanel";
import { SafeCommandsPanel } from "./components/SafeCommandsPanel";
import { ServicesPanel } from "./components/ServicesPanel";
import { SummaryCards } from "./components/SummaryCards";
import { WarningsPanel } from "./components/WarningsPanel";
import { DashboardLayout } from "./layout/DashboardLayout";
import type { DashboardModel } from "./types";

export function App() {
  const [dashboard, setDashboard] = useState<DashboardModel | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<string>("never");

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const next = await fetchDashboard();
      setDashboard(next);
      setLastRefresh(new Date().toLocaleString());
    } catch (err) {
      setError(err instanceof Error ? err.message : "unknown error");
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

      {dashboard ? (
        <>
          <ServicesPanel services={dashboard.services} />
          <GatesPanel gates={dashboard.gates} />
          <LatestImagesPanel images={dashboard.latest_images} />
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
          <WarningsPanel warnings={dashboard.warnings} />
        </>
      ) : null}

      <Typography align="center" color="text.secondary" variant="body2">
        M26.8.1 Dashboard Material Kit inspired theme. Read-only. No service control.
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
