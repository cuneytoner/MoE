import { Chip } from "@mui/material";

type Props = {
  label: string;
  tone?: "ok" | "warning" | "error" | "neutral";
};

export function StatusChip({ label, tone = "neutral" }: Props) {
  const color = tone === "ok" ? "success" : tone === "warning" ? "warning" : tone === "error" ? "error" : "default";

  return <Chip color={color} label={label} size="small" variant={tone === "neutral" ? "outlined" : "filled"} />;
}
