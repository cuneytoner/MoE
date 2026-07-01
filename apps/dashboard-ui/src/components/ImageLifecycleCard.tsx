import AutoModeOutlinedIcon from "@mui/icons-material/AutoModeOutlined";
import { Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { ImageLifecycle } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  lifecycle: ImageLifecycle;
};

export function ImageLifecycleCard({ lifecycle }: Props) {
  return (
    <Card>
      <CardHeader avatar={<AutoModeOutlinedIcon color="primary" />} title="Image Lifecycle" />
      <CardContent>
        <Stack spacing={1.5}>
          <Stack direction="row" flexWrap="wrap" gap={1}>
            <StatusChip label={lifecycle.dry_run_available ? "dry-run available" : "dry-run unavailable"} tone={lifecycle.dry_run_available ? "ok" : "warning"} />
            <StatusChip label={lifecycle.real_generation_locked ? "real locked" : "real unlocked"} tone={lifecycle.real_generation_locked ? "ok" : "warning"} />
            <StatusChip label={lifecycle.recommended_mode} tone="neutral" />
          </Stack>
          <Typography color="text.secondary" variant="body2">
            {lifecycle.next_safe_step}
          </Typography>
          <Typography color="text.secondary" variant="caption">
            Media API {readyText(lifecycle.media_api_ready)}, Media Worker {readyText(lifecycle.media_worker_ready)}, ComfyUI {readyText(lifecycle.comfyui_ready)}, Prompt Interpreter {readyText(lifecycle.prompt_interpreter_ready)}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function readyText(value: boolean) {
  return value ? "ready" : "not ready";
}
