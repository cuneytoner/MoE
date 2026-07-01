import { Box, Container, Stack } from "@mui/material";
import type { ReactNode } from "react";
import { AppHeader } from "../components/AppHeader";
import { Sidebar } from "../components/Sidebar";

type Props = {
  children: ReactNode;
  loading: boolean;
  lastRefresh: string;
  onRefresh: () => void;
};

export function DashboardLayout({ children, loading, lastRefresh, onRefresh }: Props) {
  return (
    <Box sx={{ minHeight: "100vh", bgcolor: "background.default" }}>
      <AppHeader loading={loading} lastRefresh={lastRefresh} onRefresh={onRefresh} />
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Box
          sx={{
            display: "grid",
            gap: 3,
            gridTemplateColumns: { xs: "1fr", lg: "240px minmax(0, 1fr)" },
          }}
        >
          <Sidebar />
          <Stack component="main" spacing={3} sx={{ minWidth: 0 }}>
            {children}
          </Stack>
        </Box>
      </Container>
    </Box>
  );
}
