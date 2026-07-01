import { Box, Card, CardContent, CardHeader, Divider, Stack, Typography } from "@mui/material";
import { StatusChip } from "./StatusChip";

type Props = {
  gates: Record<string, boolean>;
};

export function GatesPanel({ gates }: Props) {
  const realUnlocked = gates.gateway_real_allowed && gates.media_real_generation_enabled;
  const dryRunAvailable = gates.gateway_media_enabled;

  return (
    <Card id="gates">
      <CardHeader subheader="Generation gates are displayed only; this UI cannot change them" title="Gates" />
      <CardContent>
        <Box id="media" sx={{ display: "grid", gap: 1.5, gridTemplateColumns: { xs: "1fr", sm: "repeat(3, 1fr)" }, mb: 2 }}>
          <GateSummary label="Real generation" tone={realUnlocked ? "warning" : "ok"} value={realUnlocked ? "unlocked" : "locked"} />
          <GateSummary label="Media dry-run" tone={dryRunAvailable ? "ok" : "warning"} value={dryRunAvailable ? "available" : "unavailable"} />
          <GateSummary
            label="ComfyUI bridge"
            tone={gates.comfyui_external_bridge_required_for_docker ? "warning" : "neutral"}
            value={gates.comfyui_external_bridge_required_for_docker ? "required for Docker" : "not required"}
          />
        </Box>
        <Divider sx={{ mb: 2 }} />
        <Stack spacing={1}>
        {Object.entries(gates).map(([name, value]) => (
          <Stack alignItems="center" direction="row" justifyContent="space-between" key={name} spacing={2}>
            <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="body2">
              {name}
            </Typography>
            <StatusChip label={String(value)} tone={value ? "ok" : "neutral"} />
          </Stack>
        ))}
        </Stack>
      </CardContent>
    </Card>
  );
}

function GateSummary({ label, value, tone }: { label: string; value: string; tone: "ok" | "warning" | "neutral" }) {
  return (
    <Card variant="outlined">
      <CardContent>
        <Typography color="text.secondary" fontSize={13} fontWeight={700}>
          {label}
        </Typography>
        <Box sx={{ mt: 1 }}>
          <StatusChip label={value} tone={tone} />
        </Box>
      </CardContent>
    </Card>
  );
}
