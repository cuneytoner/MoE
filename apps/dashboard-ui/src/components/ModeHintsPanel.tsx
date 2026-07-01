import TipsAndUpdatesOutlinedIcon from "@mui/icons-material/TipsAndUpdatesOutlined";
import { Card, CardContent, CardHeader, List, ListItem, ListItemIcon, ListItemText } from "@mui/material";

type Props = {
  hints: Record<string, string>;
};

export function ModeHintsPanel({ hints }: Props) {
  return (
    <Card>
      <CardHeader subheader="Mode guidance is informational; no mode changes are applied here" title="Mode Hints" />
      <CardContent>
        <List disablePadding>
        {Object.entries(hints).map(([mode, hint]) => (
          <ListItem disableGutters key={mode}>
            <ListItemIcon>
              <TipsAndUpdatesOutlinedIcon color="primary" />
            </ListItemIcon>
            <ListItemText primary={mode} primaryTypographyProps={{ fontWeight: 800 }} secondary={hint} />
          </ListItem>
        ))}
        </List>
      </CardContent>
    </Card>
  );
}
