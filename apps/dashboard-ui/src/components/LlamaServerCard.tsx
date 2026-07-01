import SmartToyOutlinedIcon from "@mui/icons-material/SmartToyOutlined";
import { Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { ComfyUiStatus, LlamaServerStatus } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  llama: LlamaServerStatus;
  comfyui: ComfyUiStatus;
};

export function LlamaServerCard({ llama, comfyui }: Props) {
  return (
    <Card>
      <CardHeader avatar={<SmartToyOutlinedIcon color="primary" />} title="Llama Server / ComfyUI" />
      <CardContent>
        <Stack spacing={2}>
          <Stack spacing={0.75}>
            <StatusChip label={llama.reachable ? "llama reachable" : "llama unavailable"} tone={llama.reachable ? "ok" : "warning"} />
            <Typography fontWeight={800}>{llama.model || "No active model reported"}</Typography>
            <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="body2">
              {llama.url}
            </Typography>
          </Stack>
          <Stack spacing={0.75}>
            <StatusChip label={comfyui.reachable ? "comfyui reachable" : "comfyui unavailable"} tone={comfyui.reachable ? "ok" : "warning"} />
            <Typography color="text.secondary" variant="body2">
              Bridge mode: {comfyui.bridge_required ? "host.docker.internal required from Docker" : "local"}
            </Typography>
            <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
              {comfyui.url}
            </Typography>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}
