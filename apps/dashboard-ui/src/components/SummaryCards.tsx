import AutoAwesomeOutlinedIcon from "@mui/icons-material/AutoAwesomeOutlined";
import HubOutlinedIcon from "@mui/icons-material/HubOutlined";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import MemoryOutlinedIcon from "@mui/icons-material/MemoryOutlined";
import RouterOutlinedIcon from "@mui/icons-material/RouterOutlined";
import { Box, Card, CardContent, Stack, Typography } from "@mui/material";
import type { DashboardModel } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  dashboard: DashboardModel | null;
};

export function SummaryCards({ dashboard }: Props) {
  const promptInterpreter = dashboard?.services.prompt_interpreter;
  const cards = [
    {
      label: "Gateway status",
      value: dashboard?.status ?? "unknown",
      icon: <RouterOutlinedIcon />,
      tone: dashboard?.status === "ok" ? "ok" : "warning",
    },
    {
      label: "Real generation",
      value: dashboard?.gates.gateway_real_allowed ? "unlocked" : "locked",
      icon: <LockOutlinedIcon />,
      tone: dashboard?.gates.gateway_real_allowed ? "warning" : "ok",
    },
    {
      label: "Latest images",
      value: String(dashboard?.latest_images.length ?? 0),
      icon: <ImageOutlinedIcon />,
      tone: "neutral",
    },
    {
      label: "PC roles",
      value: "PC-1 GPU / PC-2 helper",
      icon: <HubOutlinedIcon />,
      tone: "neutral",
    },
    {
      label: "Media dry-run",
      value: dashboard?.gates.gateway_media_enabled ? "available" : "unavailable",
      icon: <AutoAwesomeOutlinedIcon />,
      tone: dashboard?.gates.gateway_media_enabled ? "ok" : "warning",
    },
    {
      label: "Prompt Interpreter",
      value: promptInterpreter?.status ?? "unknown",
      icon: <MemoryOutlinedIcon />,
      tone: promptInterpreter?.reachable === false ? "warning" : "ok",
    },
  ] as const;

  return (
    <Box
      id="overview"
      sx={{
        display: "grid",
        gap: 2,
        gridTemplateColumns: { xs: "1fr", sm: "repeat(2, minmax(0, 1fr))", xl: "repeat(3, minmax(0, 1fr))" },
      }}
    >
      {cards.map((card) => (
        <Card key={card.label}>
          <CardContent>
            <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
              <Box sx={{ minWidth: 0 }}>
                <Typography color="text.secondary" fontSize={13} fontWeight={700}>
                  {card.label}
                </Typography>
                <Typography sx={{ mt: 1, overflowWrap: "anywhere" }} variant="h6">
                  {card.value}
                </Typography>
              </Box>
              <Box sx={{ color: "primary.main" }}>{card.icon}</Box>
            </Stack>
            <Box sx={{ mt: 2 }}>
              <StatusChip label={card.value} tone={card.tone} />
            </Box>
          </CardContent>
        </Card>
      ))}
    </Box>
  );
}
