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
  return (
    <Card>
      <CardHeader avatar={<StorageOutlinedIcon color="primary" />} title="PC2 System" />
      <CardContent>
        <Stack spacing={1.5}>
          <StatusChip label={pc2.status} tone={pc2.status === "ok" ? "ok" : "warning"} />
          <Typography color="text.secondary" variant="body2">
            {pc2.detail}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function DockerSummaryCard({ docker }: { docker: SystemStatus["docker"] }) {
  return (
    <Card>
      <CardHeader avatar={<DnsOutlinedIcon color="primary" />} title="Docker Summary" />
      <CardContent>
        <Stack spacing={1.5}>
          <StatusChip label={docker.status} tone={docker.status === "ok" ? "ok" : "warning"} />
          <Typography color="text.secondary" variant="body2">
            {docker.detail}
          </Typography>
          <Typography color="text.secondary" variant="caption">
            Observed services: {docker.services.length}
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
