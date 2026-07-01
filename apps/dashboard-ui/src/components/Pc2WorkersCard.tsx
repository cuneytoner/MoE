import LanOutlinedIcon from "@mui/icons-material/LanOutlined";
import { Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { RuntimeDashboardModel, ServiceStatus } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  pc2: RuntimeDashboardModel["pc2"];
};

export function Pc2WorkersCard({ pc2 }: Props) {
  const workers: Array<[string, ServiceStatus]> = [
    ["Prompt Interpreter", pc2.prompt_interpreter],
    ["Nightly Learning", pc2.nightly_learning],
    ["Research Ingestion", pc2.research_ingestion],
    ["Feedback Worker", pc2.feedback_worker],
  ];

  return (
    <Card>
      <CardHeader avatar={<LanOutlinedIcon color="primary" />} subheader={`${pc2.role} at ${pc2.host}`} title="PC2 Workers" />
      <CardContent>
        <Stack spacing={1}>
          {workers.map(([label, worker]) => (
            <Stack alignItems="center" direction="row" justifyContent="space-between" key={label} spacing={2}>
              <Typography fontWeight={700}>{label}</Typography>
              <StatusChip label={worker.status} tone={worker.reachable === false ? "warning" : "ok"} />
            </Stack>
          ))}
        </Stack>
      </CardContent>
    </Card>
  );
}
