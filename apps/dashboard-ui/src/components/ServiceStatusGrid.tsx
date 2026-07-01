import { Box, Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { ServiceStatus } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  services: Record<string, ServiceStatus>;
};

const serviceOrder = ["gateway", "media_api", "media_worker", "prompt_interpreter", "control_api", "comfyui"];

export function ServiceStatusGrid({ services }: Props) {
  const entries = serviceOrder
    .filter((key) => services[key])
    .map((key) => [key, services[key]] as const);

  return (
    <Card id="services">
      <CardHeader subheader="Read-only reachability from Gateway's dashboard endpoint" title="Services" />
      <CardContent>
        <Box
          sx={{
            display: "grid",
            gap: 2,
            gridTemplateColumns: { xs: "1fr", md: "repeat(2, minmax(0, 1fr))" },
          }}
        >
          {entries.map(([key, service]) => (
            <Card key={key} variant="outlined">
              <CardContent>
                <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
                  <Box sx={{ minWidth: 0 }}>
                    <Typography fontWeight={800}>{service.service}</Typography>
                    <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="body2">
                      {service.url}
                    </Typography>
                  </Box>
                  <StatusChip
                    label={service.status}
                    tone={service.reachable === false ? "warning" : service.status === "ok" ? "ok" : "neutral"}
                  />
                </Stack>
                {service.detail ? (
                  <Typography color="text.secondary" sx={{ mt: 1 }} variant="body2">
                    {service.detail}
                  </Typography>
                ) : null}
              </CardContent>
            </Card>
          ))}
        </Box>
      </CardContent>
    </Card>
  );
}
