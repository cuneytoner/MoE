import ComputerOutlinedIcon from "@mui/icons-material/ComputerOutlined";
import DnsOutlinedIcon from "@mui/icons-material/DnsOutlined";
import StorageOutlinedIcon from "@mui/icons-material/StorageOutlined";
import { Box, Card, CardContent, CardHeader, LinearProgress, Stack, Typography } from "@mui/material";
import type { SystemStatus } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  system: SystemStatus;
};

export function SystemResourceCards({ system }: Props) {
  return (
    <>
      <Pc1SystemCard system={system.pc1} />
      <Pc2SystemCard pc2={system.pc2} />
      <DockerSummaryCard docker={system.docker} />
    </>
  );
}

function Pc1SystemCard({ system }: { system: SystemStatus["pc1"] }) {
  return (
    <Card>
      <CardHeader avatar={<ComputerOutlinedIcon color="primary" />} title="PC1 System" />
      <CardContent>
        <Stack spacing={2}>
          <MetricBar
            label={`RAM ${system.memory.used_mb} / ${system.memory.total_mb} MB`}
            value={system.memory.used_percent}
          />
          <MetricBar
            label={`Disk ${system.disk.used_gb} / ${system.disk.total_gb} GB on ${system.disk.path}`}
            value={system.disk.used_percent}
          />
          <Box sx={{ display: "grid", gap: 1, gridTemplateColumns: "repeat(2, minmax(0, 1fr))" }}>
            <SmallMetric label="Load 1m" value={String(system.cpu.load_1m)} />
            <SmallMetric label="Load 5m" value={String(system.cpu.load_5m)} />
            <SmallMetric label="Load 15m" value={String(system.cpu.load_15m)} />
            <SmallMetric label="CPU count" value={String(system.cpu.cpu_count)} />
          </Box>
          <Typography color="text.secondary" variant="body2">
            Uptime: {system.uptime.human} ({system.uptime.seconds}s)
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function Pc2SystemCard({ pc2 }: { pc2: SystemStatus["pc2"] }) {
  const hasMetrics = pc2.status === "ok" && pc2.memory && pc2.cpu && pc2.disk && pc2.uptime;

  return (
    <Card>
      <CardHeader avatar={<StorageOutlinedIcon color="primary" />} title="PC2 System" />
      <CardContent>
        {hasMetrics ? (
          <Stack spacing={2}>
            <StatusChip label="ok" tone="ok" />
            <MetricBar label={`RAM ${pc2.memory?.used_mb} / ${pc2.memory?.total_mb} MB`} value={pc2.memory?.used_percent ?? 0} />
            <MetricBar label={`Disk ${pc2.disk?.used_gb} / ${pc2.disk?.total_gb} GB on ${pc2.disk?.path}`} value={pc2.disk?.used_percent ?? 0} />
            <Box sx={{ display: "grid", gap: 1, gridTemplateColumns: "repeat(2, minmax(0, 1fr))" }}>
              <SmallMetric label="Load 1m" value={String(pc2.cpu?.load_1m)} />
              <SmallMetric label="Load 5m" value={String(pc2.cpu?.load_5m)} />
              <SmallMetric label="Load 15m" value={String(pc2.cpu?.load_15m)} />
              <SmallMetric label="CPU count" value={String(pc2.cpu?.cpu_count)} />
            </Box>
            <Typography color="text.secondary" variant="body2">
              Uptime: {pc2.uptime?.human} ({pc2.uptime?.seconds}s)
            </Typography>
          </Stack>
        ) : (
          <Stack spacing={1.5}>
            <StatusChip label={pc2.status} tone="warning" />
            <Typography color="text.secondary" variant="body2">
              {pc2.detail || "PC2 system status is unavailable."}
            </Typography>
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

function DockerSummaryCard({ docker }: { docker: SystemStatus["docker"] }) {
  const summary = docker.summary;

  return (
    <Card>
      <CardHeader avatar={<DnsOutlinedIcon color="primary" />} title="Docker Summary" />
      <CardContent>
        <Stack spacing={1.5}>
          <StatusChip label={docker.status} tone={docker.status === "ok" ? "ok" : "warning"} />
          {summary ? (
            <Box sx={{ display: "grid", gap: 1, gridTemplateColumns: "repeat(2, minmax(0, 1fr))" }}>
              <SmallMetric label="Total" value={String(summary.total)} />
              <SmallMetric label="Running" value={String(summary.running)} />
              <SmallMetric label="Healthy" value={String(summary.healthy)} />
              <SmallMetric label="Unhealthy" value={String(summary.unhealthy)} />
              <SmallMetric label="Missing" value={String(summary.missing)} />
              <SmallMetric label="Observed" value={String(docker.services.length)} />
            </Box>
          ) : null}
          {docker.detail ? (
            <Typography color="text.secondary" variant="body2">
              {docker.detail}
            </Typography>
          ) : null}
          <Typography color="text.secondary" variant="caption">
            {docker.generated_at ? `Generated: ${new Date(docker.generated_at).toLocaleString()}` : `Observed services: ${docker.services.length}`}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function MetricBar({ label, value }: { label: string; value: number }) {
  return (
    <Stack spacing={0.75}>
      <Stack direction="row" justifyContent="space-between" spacing={2}>
        <Typography fontWeight={700} variant="body2">
          {label}
        </Typography>
        <Typography color="text.secondary" variant="body2">
          {value}%
        </Typography>
      </Stack>
      <LinearProgress color={value > 85 ? "warning" : "primary"} value={Math.min(100, value)} variant="determinate" />
    </Stack>
  );
}

function SmallMetric({ label, value }: { label: string; value: string }) {
  return (
    <Box sx={{ bgcolor: "grey.100", borderRadius: 1, p: 1 }}>
      <Typography color="text.secondary" fontSize={12} fontWeight={700}>
        {label}
      </Typography>
      <Typography fontWeight={800}>{value}</Typography>
    </Box>
  );
}
