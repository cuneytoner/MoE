import { useState } from "react";
import ArticleOutlinedIcon from "@mui/icons-material/ArticleOutlined";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import InsertDriveFileOutlinedIcon from "@mui/icons-material/InsertDriveFileOutlined";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  CircularProgress,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  Stack,
  Typography,
} from "@mui/material";
import { fetchOutputCardMetadata, gatewayBaseUrl } from "../api";
import type { OutputCard, OutputCardMetadataResponse } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  cards: OutputCard[];
  error: string;
  loading: boolean;
};

const MAX_VISIBLE_CARDS = 12;

export function OutputCards({ cards, error, loading }: Props) {
  const visibleCards = cards.slice(0, MAX_VISIBLE_CARDS);
  const [metadataCard, setMetadataCard] = useState<OutputCard | null>(null);
  const [metadataResponse, setMetadataResponse] = useState<OutputCardMetadataResponse | null>(null);
  const [metadataLoading, setMetadataLoading] = useState(false);
  const [metadataError, setMetadataError] = useState("");

  async function openMetadata(card: OutputCard) {
    setMetadataCard(card);
    setMetadataResponse(null);
    setMetadataError("");
    setMetadataLoading(true);
    try {
      setMetadataResponse(await fetchOutputCardMetadata(card.id));
    } catch (err) {
      setMetadataError(err instanceof Error ? err.message : "unknown metadata error");
    } finally {
      setMetadataLoading(false);
    }
  }

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
                <OutputCardTile card={card} key={card.id} onViewMetadata={openMetadata} />
              ))}
            </Box>
          ) : null}
        </Stack>
      </CardContent>
      <MetadataDialog
        card={metadataCard}
        error={metadataError}
        loading={metadataLoading}
        metadata={metadataResponse?.metadata ?? null}
        onClose={() => {
          setMetadataCard(null);
          setMetadataResponse(null);
          setMetadataError("");
        }}
      />
    </Card>
  );
}

function OutputCardTile({ card, onViewMetadata }: { card: OutputCard; onViewMetadata: (card: OutputCard) => void }) {
  const [previewFailed, setPreviewFailed] = useState(false);
  const shouldShowImagePreview = card.type === "image" && card.preview_available === true && !previewFailed;
  const previewUrl = `${gatewayBaseUrl()}/gateway/media/output-preview/${encodeURIComponent(card.id)}`;

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
              height: 120,
              justifyContent: "center",
              overflow: "hidden",
              position: "relative",
            }}
          >
            {shouldShowImagePreview ? (
              <Box
                alt=""
                component="img"
                loading="lazy"
                onError={() => setPreviewFailed(true)}
                src={previewUrl}
                sx={{
                  display: "block",
                  height: "100%",
                  objectFit: "cover",
                  width: "100%",
                }}
              />
            ) : card.type === "image" ? (
              <Stack alignItems="center" spacing={0.5}>
                <ImageOutlinedIcon color={previewFailed ? "disabled" : "primary"} fontSize="large" />
                {previewFailed ? (
                  <Typography color="text.secondary" variant="caption">
                    preview unavailable
                  </Typography>
                ) : null}
              </Stack>
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

          {card.metadata_available ? (
            <Box>
              <Button onClick={() => onViewMetadata(card)} size="small" variant="outlined">
                View metadata
              </Button>
            </Box>
          ) : null}

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

function MetadataDialog({
  card,
  error,
  loading,
  metadata,
  onClose,
}: {
  card: OutputCard | null;
  error: string;
  loading: boolean;
  metadata: Record<string, unknown> | null;
  onClose: () => void;
}) {
  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open={card !== null}>
      <DialogTitle>Output metadata</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ pb: 1 }}>
          {card ? (
            <Box>
              <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                {card.name}
              </Typography>
              <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
                {card.id}
              </Typography>
            </Box>
          ) : null}

          {loading ? (
            <Stack alignItems="center" direction="row" spacing={1}>
              <CircularProgress size={18} />
              <Typography color="text.secondary" variant="body2">
                Loading metadata.
              </Typography>
            </Stack>
          ) : null}

          {error ? (
            <Alert severity="warning" variant="outlined">
              Metadata unavailable: {error}
            </Alert>
          ) : null}

          {metadata ? <MetadataDetails cardType={card?.type ?? ""} metadata={metadata} /> : null}
        </Stack>
      </DialogContent>
    </Dialog>
  );
}

function MetadataDetails({ cardType, metadata }: { cardType: string; metadata: Record<string, unknown> }) {
  const fields =
    cardType === "image"
      ? [
          "prompt",
          "seed",
          "width",
          "height",
          "steps",
          "workflow",
          "model_name",
          "model_family",
          "script",
          "safety_label",
          "relative_runtime_path",
          "notes",
        ]
      : [
          "project",
          "drawing_kind",
          "units",
          "geometry",
          "geometry_summary",
          "script",
          "safety_label",
          "relative_runtime_path",
          "notes",
        ];

  return (
    <Stack spacing={2}>
      <Box sx={{ display: "grid", gap: 1, gridTemplateColumns: { xs: "1fr", sm: "160px minmax(0, 1fr)" } }}>
        {fields.map((field) => (
          <MetadataField field={field} key={field} value={metadata[field]} />
        ))}
      </Box>
      <Divider />
      <Box>
        <Typography gutterBottom fontWeight={800} variant="body2">
          Raw JSON
        </Typography>
        <Box
          component="pre"
          sx={{
            bgcolor: "background.default",
            border: "1px solid rgba(145, 158, 171, 0.24)",
            borderRadius: 1,
            fontFamily: "monospace",
            fontSize: 12,
            maxHeight: 260,
            overflow: "auto",
            p: 1.5,
            whiteSpace: "pre-wrap",
            wordBreak: "break-word",
          }}
        >
          {JSON.stringify(metadata, null, 2)}
        </Box>
      </Box>
    </Stack>
  );
}

function MetadataField({ field, value }: { field: string; value: unknown }) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  return (
    <>
      <Typography color="text.secondary" variant="caption">
        {field}
      </Typography>
      <Typography sx={{ overflowWrap: "anywhere" }} variant="body2">
        {formatMetadataValue(value)}
      </Typography>
    </>
  );
}

function formatMetadataValue(value: unknown): string {
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  return JSON.stringify(value);
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
