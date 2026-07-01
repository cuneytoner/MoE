import CodeRoundedIcon from "@mui/icons-material/CodeRounded";
import DashboardRoundedIcon from "@mui/icons-material/DashboardRounded";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import MemoryOutlinedIcon from "@mui/icons-material/MemoryOutlined";
import PermMediaOutlinedIcon from "@mui/icons-material/PermMediaOutlined";
import StorageRoundedIcon from "@mui/icons-material/StorageRounded";
import { Card, List, ListItemButton, ListItemIcon, ListItemText, Typography } from "@mui/material";
import type { ReactNode } from "react";

const items: Array<{ label: string; href: string; icon: ReactNode }> = [
  { label: "Overview", href: "#overview", icon: <DashboardRoundedIcon /> },
  { label: "Runtime", href: "#runtime", icon: <MemoryOutlinedIcon /> },
  { label: "Services", href: "#services", icon: <StorageRoundedIcon /> },
  { label: "Media", href: "#media", icon: <PermMediaOutlinedIcon /> },
  { label: "Gates", href: "#gates", icon: <LockOutlinedIcon /> },
  { label: "Images", href: "#images", icon: <ImageOutlinedIcon /> },
  { label: "Commands", href: "#commands", icon: <CodeRoundedIcon /> },
];

export function Sidebar() {
  return (
    <Card
      component="nav"
      sx={{
        alignSelf: "start",
        display: { xs: "none", lg: "block" },
        p: 1,
        position: "sticky",
        top: 96,
      }}
    >
      <Typography color="text.secondary" fontSize={12} fontWeight={800} px={2} py={1} textTransform="uppercase">
        Dashboard
      </Typography>
      <List dense>
        {items.map((item) => (
          <ListItemButton component="a" href={item.href} key={item.href} sx={{ borderRadius: 1 }}>
            <ListItemIcon sx={{ color: "text.secondary", minWidth: 36 }}>{item.icon}</ListItemIcon>
            <ListItemText primary={item.label} primaryTypographyProps={{ fontWeight: 700 }} />
          </ListItemButton>
        ))}
      </List>
    </Card>
  );
}
