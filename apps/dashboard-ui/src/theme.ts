import { createTheme } from "@mui/material/styles";

export const dashboardTheme = createTheme({
  palette: {
    mode: "light",
    background: {
      default: "#f5f7fb",
      paper: "#ffffff",
    },
    primary: {
      main: "#2065d1",
      dark: "#103996",
    },
    success: {
      main: "#11845b",
    },
    warning: {
      main: "#b76e00",
    },
    error: {
      main: "#b42318",
    },
    text: {
      primary: "#1c252e",
      secondary: "#637381",
    },
  },
  shape: {
    borderRadius: 8,
  },
  typography: {
    fontFamily:
      'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    h4: {
      fontWeight: 800,
      letterSpacing: 0,
    },
    h6: {
      fontWeight: 800,
      letterSpacing: 0,
    },
    button: {
      fontWeight: 700,
      textTransform: "none",
    },
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          border: "1px solid rgba(145, 158, 171, 0.2)",
          boxShadow: "0 8px 24px rgba(145, 158, 171, 0.12)",
        },
      },
    },
    MuiCardHeader: {
      styleOverrides: {
        title: {
          fontSize: "1rem",
          fontWeight: 800,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 700,
        },
      },
    },
  },
});
