import WarningAmberRoundedIcon from "@mui/icons-material/WarningAmberRounded";
import { Alert, Card, CardContent, CardHeader, Stack } from "@mui/material";

type Props = {
  warnings: string[];
};

export function WarningsPanel({ warnings }: Props) {
  if (warnings.length === 0) {
    return null;
  }

  return (
    <Card>
      <CardHeader title="Warnings" />
      <CardContent>
        <Stack spacing={1}>
          {warnings.map((warning) => (
            <Alert icon={<WarningAmberRoundedIcon />} key={warning} severity="warning" variant="outlined">
              {warning}
            </Alert>
          ))}
        </Stack>
      </CardContent>
    </Card>
  );
}
