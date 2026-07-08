import ArticleOutlinedIcon from "@mui/icons-material/ArticleOutlined";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import InsertDriveFileOutlinedIcon from "@mui/icons-material/InsertDriveFileOutlined";
import { Alert, Box, Card, CardContent, CardHeader, Chip, Stack, Typography } from "@mui/material";
import type { OutputCard } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  cards: OutputCard[];
  error: string;
  loading: boolean;
};

const MAX_VISIBLE_CARDS = 12;

export function OutputCards({ cards, error, loading }: Props) {
  const visibleCards = cards.slice(0, MAX_VISIBLE_CARDS);
  return (
    <Card id="media-output-cards">
      <CardHeader
        subheader="Read-only view of generated images and deterministic drawings."
        title="Media Output Cards"
      />
      <CardContent>
        <Stack spacing={2}>
          <Stack
            alignItems={{ xs: "flex-start", sm: "center" }}
            direction={{ xs: "column", sm: "row" }}
            justifyContent="space-between"
            spacing={1}
          >
            <Typography color="text.secondary" variant="body2">
              Showing {visibleCards.length} of {cards.length} cards
            </Typography>
            <StatusChip label="read-only" tone="ok" />
          </Stack>

          {error ? (
            <Alert severity="warning" variant="outlined">
              Output cards unavailable: {error}
            </Alert>
          ) : null}

          {!error && loading && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              Loading output cards.
            </Typography>
          ) : null}

          {!error && !loading && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              No generated image or SVG drawing cards reported yet.
            </Typography>
          ) : null}

          {visibleCards.length > 0 ? (
            <Box
              sx={{
                display: "grid",
                gap: 2,
                gridTemplateColumns: { xs: "1fr", md: "repeat(2, minmax(0, 1fr))", xl: "repeat(3, minmax(0, 1fr))" },
              }}
            >
              {visibleCards.map((card) => (
                <OutputCardTile card={card} key={card.id} />
              ))}
            </Box>
          ) : null}
        </Stack>
      </CardContent>
    </Card>
  );
}

function OutputCardTile({ card }: { card: OutputCard }) {
  return (
    <Card variant="outlined">
      <CardContent>
        <Stack spacing={1.5}>
          <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
            <Stack direction="row" spacing={1.25} sx={{ minWidth: 0 }}>
              <Box sx={{ color: card.type === "image" ? "primary.main" : "text.secondary", pt: 0.25 }}>
                {card.type === "image" ? <ImageOutlinedIcon /> : <ArticleOutlinedIcon />}
              </Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                  {card.name}
                </Typography>
                <Typography color="text.secondary" variant="caption">
                  {new Date(card.modified).toLocaleString()}
                </Typography>
              </Box>
            </Stack>
            <StatusChip label={card.type} tone="neutral" />
          </Stack>

          <Box
            sx={{
              alignItems: "center",
              bgcolor: "background.default",
              border: "1px solid rgba(145, 158, 171, 0.24)",
              borderRadius: 1,
              display: "flex",
              height: 72,
              justifyContent: "center",
            }}
          >
            {card.preview_available ? (
              <ImageOutlinedIcon color="primary" fontSize="large" />
            ) : (
              <InsertDriveFileOutlinedIcon color="disabled" fontSize="large" />
            )}
          </Box>

          <Stack direction="row" flexWrap="wrap" gap={1}>
            <StatusChip label={card.safety_label} tone={safetyTone(card.safety_label)} />
            <Chip label={card.source} size="small" variant="outlined" />
            <Chip label={card.metadata_available ? "metadata" : "no metadata"} size="small" variant="outlined" />
            <Chip label={formatBytes(card.size_bytes)} size="small" variant="outlined" />
          </Stack>

          {card.tags.length > 0 ? (
            <Stack direction="row" flexWrap="wrap" gap={0.75}>
              {card.tags.map((tag) => (
                <Chip key={tag} label={tag} size="small" variant="outlined" />
              ))}
            </Stack>
          ) : null}

          <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
            {card.relative_runtime_path}
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function safetyTone(label: string): "ok" | "warning" | "error" | "neutral" {
  if (label === "draft_drawing" || label === "visual_reference_only") {
    return "warning";
  }
  if (label === "deterministic_drawing") {
    return "ok";
  }
  return "neutral";
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
