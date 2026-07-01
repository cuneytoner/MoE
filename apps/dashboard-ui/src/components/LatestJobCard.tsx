import AssignmentOutlinedIcon from "@mui/icons-material/AssignmentOutlined";
import { Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { RuntimeJobSummary } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  job: RuntimeJobSummary | null;
  jobsDir: string;
  totalVisibleJobs: number;
};

export function LatestJobCard({ job, jobsDir, totalVisibleJobs }: Props) {
  return (
    <Card>
      <CardHeader avatar={<AssignmentOutlinedIcon color="primary" />} title="Latest Media Job" />
      <CardContent>
        {job ? (
          <Stack spacing={1}>
            <Typography fontWeight={800}>{job.job_id}</Typography>
            <Stack direction="row" flexWrap="wrap" gap={1}>
              <StatusChip label={job.state || "unknown"} tone={job.state?.startsWith("processed") ? "ok" : "neutral"} />
              <StatusChip label={job.mode || "unknown"} tone={job.mode === "real" ? "warning" : "ok"} />
              <StatusChip label={job.job_type || "unknown"} tone="neutral" />
            </Stack>
            <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="body2">
              {job.job_path}
            </Typography>
          </Stack>
        ) : (
          <Typography color="text.secondary" variant="body2">
            No visible media jobs yet.
          </Typography>
        )}
        <Typography color="text.secondary" sx={{ mt: 2, overflowWrap: "anywhere" }} variant="caption">
          {totalVisibleJobs} visible job file(s) in {jobsDir}
        </Typography>
      </CardContent>
    </Card>
  );
}
