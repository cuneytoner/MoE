import RefreshRoundedIcon from "@mui/icons-material/RefreshRounded";
import ShieldOutlinedIcon from "@mui/icons-material/ShieldOutlined";
import { AppBar, Box, Button, Chip, Toolbar, Typography } from "@mui/material";

type Props = {
  loading: boolean;
  lastRefresh: string;
  onRefresh: () => void;
};

export function AppHeader({ loading, lastRefresh, onRefresh }: Props) {
  return (
    <AppBar
      color="inherit"
      elevation={0}
      position="sticky"
      sx={{ borderBottom: "1px solid", borderColor: "divider" }}
    >
      <Toolbar sx={{ gap: 2, minHeight: 72, px: { xs: 2, sm: 3 } }}>
        <Box sx={{ flexGrow: 1, minWidth: 0 }}>
          <Typography color="text.secondary" fontSize={12} fontWeight={800} letterSpacing={0} textTransform="uppercase">
            AI Brain OS
          </Typography>
          <Typography noWrap variant="h6">
            MoE Control Dashboard
          </Typography>
        </Box>
        <Chip color="success" icon={<ShieldOutlinedIcon />} label="Read-only MVP" variant="outlined" />
        <Typography color="text.secondary" sx={{ display: { xs: "none", md: "block" } }} variant="body2">
          Last refresh: {lastRefresh}
        </Typography>
        <Button
          disabled={loading}
          onClick={onRefresh}
          startIcon={<RefreshRoundedIcon />}
          variant="contained"
        >
          {loading ? "Refreshing" : "Refresh"}
        </Button>
      </Toolbar>
    </AppBar>
  );
}
