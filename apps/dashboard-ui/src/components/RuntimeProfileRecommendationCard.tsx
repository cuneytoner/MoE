import TuneRoundedIcon from "@mui/icons-material/TuneRounded";
import { Card, CardContent, CardHeader, Stack, Typography } from "@mui/material";
import type { RuntimeProfileRecommendation, RuntimeProfileSummary } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  summary?: RuntimeProfileSummary;
};

function tone(value: string) {
  return value === "compatible" || value === "low" ? "ok" : value === "high" || value === "unknown" ? "error" : "warning";
}

function RecommendationRow({ label, recommendation }: { label: string; recommendation: RuntimeProfileRecommendation }) {
  return (
    <Stack spacing={0.75}>
      <Typography color="text.secondary" fontSize={13} fontWeight={800}>
        {label}
      </Typography>
      <Typography fontWeight={800}>{recommendation.model_target || "Review required"}</Typography>
      <Stack direction="row" flexWrap="wrap" gap={1}>
        <StatusChip label={recommendation.compatibility} tone={tone(recommendation.compatibility)} />
        <StatusChip label={`risk: ${recommendation.risk_level}`} tone={tone(recommendation.risk_level)} />
      </Stack>
    </Stack>
  );
}

export function RuntimeProfileRecommendationCard({ summary }: Props) {
  if (!summary) {
    return (
      <Card>
        <CardHeader avatar={<TuneRoundedIcon color="primary" />} title="Runtime Profile Recommendation" />
        <CardContent>
          <Typography color="text.secondary" variant="body2">
            Waiting for profile recommendation summary.
          </Typography>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader avatar={<TuneRoundedIcon color="primary" />} title="Runtime Profile Recommendation" />
      <CardContent>
        <Stack spacing={1.5}>
          <Stack direction="row" flexWrap="wrap" gap={1}>
            <StatusChip label={summary.status} tone={summary.status === "ok" ? "ok" : "warning"} />
            <StatusChip label="manual only" tone="neutral" />
            <StatusChip label={`${summary.warnings.length} warnings`} tone={summary.warnings.length ? "warning" : "ok"} />
          </Stack>
          <RecommendationRow label="Default" recommendation={summary.recommendations.default} />
          <RecommendationRow label="Review" recommendation={summary.recommendations.review} />
          <RecommendationRow label="Fallback" recommendation={summary.recommendations.fallback} />
          <Typography color="text.secondary" variant="body2">
            Visibility only. Runtime changes remain manual and outside this dashboard.
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}
