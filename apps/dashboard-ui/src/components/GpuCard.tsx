import MemoryRoundedIcon from "@mui/icons-material/MemoryRounded";
import { Card, CardContent, CardHeader, LinearProgress, Stack, Typography } from "@mui/material";
import type { GpuStatus } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  gpu: GpuStatus;
};

export function GpuCard({ gpu }: Props) {
  const usedPercent = gpu.memory_total_mb > 0 ? Math.round((gpu.memory_used_mb / gpu.memory_total_mb) * 100) : 0;

  return (
    <Card>
      <CardHeader avatar={<MemoryRoundedIcon color="primary" />} title="GPU" />
      <CardContent>
        <Stack spacing={1.5}>
          <StatusChip label={gpu.available ? "available" : "unavailable"} tone={gpu.available ? "ok" : "warning"} />
          <Typography fontWeight={800}>{gpu.name || "No GPU reported"}</Typography>
          <Typography color="text.secondary" variant="body2">
            VRAM {gpu.memory_used_mb} / {gpu.memory_total_mb} MB used, {gpu.memory_free_mb} MB free
          </Typography>
          <LinearProgress value={Math.min(100, usedPercent)} variant="determinate" />
          <Typography color="text.secondary" variant="body2">
            Utilization: {gpu.utilization_gpu_percent}%
          </Typography>
          <Typography color="text.secondary" variant="caption">
            {gpu.detail}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}
