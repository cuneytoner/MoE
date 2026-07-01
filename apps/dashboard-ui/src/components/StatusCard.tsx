import { Card, CardContent, Typography } from "@mui/material";
import { StatusChip } from "./StatusChip";

type Props = {
  label: string;
  value: string;
  tone?: "default" | "good" | "warn";
};

export function StatusCard({ label, value, tone = "default" }: Props) {
  const chipTone = tone === "good" ? "ok" : tone === "warn" ? "warning" : "neutral";

  return (
    <Card>
      <CardContent>
        <Typography color="text.secondary" fontSize={13} fontWeight={700}>
          {label}
        </Typography>
        <Typography sx={{ my: 1, overflowWrap: "anywhere" }} variant="h6">
          {value}
        </Typography>
        <StatusChip label={value} tone={chipTone} />
      </CardContent>
    </Card>
  );
}
