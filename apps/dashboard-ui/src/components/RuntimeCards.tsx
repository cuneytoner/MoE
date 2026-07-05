import { Alert, Box, Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { RuntimeDashboardModel } from "../types";
import { GpuCard } from "./GpuCard";
import { ImageLifecycleCard } from "./ImageLifecycleCard";
import { LatestJobCard } from "./LatestJobCard";
import { LlamaServerCard } from "./LlamaServerCard";
import { Pc2WorkersCard } from "./Pc2WorkersCard";
import { RuntimeProfileRecommendationCard } from "./RuntimeProfileRecommendationCard";

type Props = {
  runtime: RuntimeDashboardModel | null;
  error: string;
};

export function RuntimeCards({ runtime, error }: Props) {
  if (error) {
    return (
      <Alert id="runtime" severity="warning" variant="outlined">
        Runtime dashboard unavailable: {error}
      </Alert>
    );
  }

  if (!runtime) {
    return (
      <Card id="runtime">
        <CardHeader title="Runtime Cards" />
        <CardContent>
          <Typography color="text.secondary" variant="body2">
            Waiting for runtime dashboard data.
          </Typography>
        </CardContent>
      </Card>
    );
  }

  return (
    <Stack id="runtime" spacing={2}>
      <Typography variant="h6">Runtime Cards</Typography>
      <Box sx={{ display: "grid", gap: 2, gridTemplateColumns: { xs: "1fr", lg: "repeat(2, minmax(0, 1fr))" } }}>
        <GpuCard gpu={runtime.pc1.gpu} />
        <LlamaServerCard comfyui={runtime.pc1.comfyui} llama={runtime.pc1.llama_server} />
        <Pc2WorkersCard pc2={runtime.pc2} />
        <LatestJobCard
          job={runtime.media_jobs.latest_job}
          jobsDir={runtime.media_jobs.jobs_dir}
          totalVisibleJobs={runtime.media_jobs.total_visible_jobs}
        />
        <ImageLifecycleCard lifecycle={runtime.image_lifecycle} />
        <RuntimeProfileRecommendationCard summary={runtime.runtime_profile_summary} />
      </Box>
    </Stack>
  );
}
