import ContentCopyRoundedIcon from "@mui/icons-material/ContentCopyRounded";
import { Box, Card, CardContent, CardHeader, IconButton, Stack, Tooltip, Typography } from "@mui/material";

type Props = {
  commands: Record<string, string[]>;
};

export function SafeCommandsPanel({ commands }: Props) {
  return (
    <Card id="commands">
      <CardHeader subheader="Commands are displayed as text only. Copying does not execute them." title="Safe Command Hints" />
      <CardContent>
        <Stack spacing={2}>
        {Object.entries(commands).map(([group, values]) => (
          <Box key={group}>
            <Typography fontWeight={800} gutterBottom>
              {group}
            </Typography>
            <Stack spacing={1}>
            {values.map((command) => (
              <Box
                component="code"
                key={command}
                sx={{
                  alignItems: "center",
                  bgcolor: "grey.100",
                  border: "1px solid",
                  borderColor: "divider",
                  borderRadius: 1,
                  display: "flex",
                  gap: 1,
                  justifyContent: "space-between",
                  px: 1.5,
                  py: 1,
                }}
              >
                <Typography component="span" fontFamily="monospace" fontSize={13} sx={{ overflowWrap: "anywhere" }}>
                  {command}
                </Typography>
                <Tooltip title="Copy command text">
                  <IconButton aria-label={`Copy ${group} command`} onClick={() => void navigator.clipboard.writeText(command)} size="small">
                    <ContentCopyRoundedIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Box>
            ))}
            </Stack>
          </Box>
        ))}
        </Stack>
      </CardContent>
    </Card>
  );
}
