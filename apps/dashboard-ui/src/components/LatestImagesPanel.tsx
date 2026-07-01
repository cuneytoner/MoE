import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import { Box, Card, CardContent, CardHeader, List, ListItem, ListItemIcon, ListItemText, Typography } from "@mui/material";
import type { ImageInfo } from "../types";

type Props = {
  images: ImageInfo[];
};

export function LatestImagesPanel({ images }: Props) {
  return (
    <Card id="images">
      <CardHeader subheader="Paths only. No generated image bytes are served by this dashboard." title="Latest Images" />
      <CardContent>
        <List disablePadding>
        {images.map((image) => (
          <ListItem
            disableGutters
            key={image.path}
            secondaryAction={
              <Box sx={{ display: { xs: "none", md: "block" }, textAlign: "right" }}>
                <Typography fontWeight={800} variant="body2">
                  {formatBytes(image.size_bytes)}
                </Typography>
                <Typography color="text.secondary" variant="caption">
                  {new Date(image.modified).toLocaleString()}
                </Typography>
              </Box>
            }
          >
            <ListItemIcon>
              <ImageOutlinedIcon color="primary" />
            </ListItemIcon>
            <ListItemText
              primary={image.name}
              primaryTypographyProps={{ fontWeight: 800 }}
              secondary={image.path}
              secondaryTypographyProps={{ sx: { overflowWrap: "anywhere" } }}
            />
          </ListItem>
        ))}
        </List>
        {images.length === 0 ? (
          <Typography color="text.secondary" variant="body2">
            No generated image paths reported yet.
          </Typography>
        ) : null}
      </CardContent>
    </Card>
  );
}

function formatBytes(value: number) {
  if (value < 1024) {
    return `${value} B`;
  }
  if (value < 1024 * 1024) {
    return `${(value / 1024).toFixed(1)} KB`;
  }
  return `${(value / 1024 / 1024).toFixed(1)} MB`;
}
