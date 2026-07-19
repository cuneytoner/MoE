import AnimationOutlinedIcon from "@mui/icons-material/AnimationOutlined";
import ImageNotSupportedOutlinedIcon from "@mui/icons-material/ImageNotSupportedOutlined";
import { Alert, Box, Button, Card, CardContent, CardHeader, Chip, Stack, Typography } from "@mui/material";
import type { ReactNode } from "react";
import type { AnimationOutputCard, AnimationOutputCardsResponse } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  activeBoardId: string;
  addingCardId: string;
  cardsResponse: AnimationOutputCardsResponse | null;
  error: string;
  loading: boolean;
  onAddToBoard: (card: AnimationOutputCard) => void;
};

const MAX_VISIBLE_CARDS = 12;
const VISIBLE_CHIP_LIMIT = 6;

export function AnimationOutputCards({ activeBoardId, addingCardId, cardsResponse, error, loading, onAddToBoard }: Props) {
  const cards = cardsResponse?.cards ?? [];
  const visibleCards = cards.slice(0, MAX_VISIBLE_CARDS);
  const metadataMissing = cardsResponse?.metadata_dir_available === false;
  const reportsMissing = cardsResponse?.reports_dir_available === false;
  const invalidCount = cardsResponse?.invalid_count ?? 0;
  const safetyUnsafe = cardsResponse ? hasUnsafeSafetyFlags(cardsResponse) : false;

  return (
    <Card id="animation-output-cards">
      <CardHeader
        subheader="Read-only view of validated animation metadata and verified sampled PNG previews."
        title="Animation Output Cards"
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

          {cardsResponse ? (
            <Stack direction="row" flexWrap="wrap" gap={1}>
              <StatusChip
                label={cardsResponse.metadata_dir_available ? "metadata available" : "metadata unavailable"}
                tone={cardsResponse.metadata_dir_available ? "ok" : "warning"}
              />
              <StatusChip
                label={cardsResponse.reports_dir_available ? "reports available" : "reports unavailable"}
                tone={cardsResponse.reports_dir_available ? "ok" : "warning"}
              />
              <Chip label={`cards ${cardsResponse.card_count}`} size="small" variant="outlined" />
              <Chip label={`invalid metadata ${cardsResponse.invalid_count}`} size="small" variant="outlined" />
              <Chip label={`preview reports ${cardsResponse.preview_report_count}`} size="small" variant="outlined" />
              <Chip label={`verified previews ${cardsResponse.verified_preview_count}`} size="small" variant="outlined" />
            </Stack>
          ) : null}

          {error ? (
            <Alert severity="warning" variant="outlined">
              Animation output cards unavailable: {error}
            </Alert>
          ) : null}

          {!error && safetyUnsafe ? (
            <Alert severity="error" variant="outlined">
              Unsafe animation card API flags detected. Do not treat these cards as read-only.
            </Alert>
          ) : null}

          {!error && loading && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              Loading animation output cards.
            </Typography>
          ) : null}

          {!error && !loading && metadataMissing ? (
            <Alert severity="info" variant="outlined">
              Animation metadata directory is not available yet.
            </Alert>
          ) : null}

          {!error && reportsMissing ? (
            <Alert severity="info" variant="outlined">
              Animation preview reports are not available yet. Metadata cards remain read-only and usable.
            </Alert>
          ) : null}

          {!error && !loading && !metadataMissing && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              No validated animation output metadata reported yet.
            </Typography>
          ) : null}

          {!error && invalidCount > 0 ? (
            <Alert severity="warning" variant="outlined">
              {invalidCount} invalid animation metadata sidecar(s) were skipped.
            </Alert>
          ) : null}

          {!error && cardsResponse && cardsResponse.warnings.length > 0 ? (
            <Alert severity="warning" variant="outlined">
              <Stack spacing={0.5}>
                {cardsResponse.warnings.slice(0, 5).map((warning) => (
                  <Typography key={warning} sx={{ overflowWrap: "anywhere" }} variant="body2">
                    {warning}
                  </Typography>
                ))}
              </Stack>
            </Alert>
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
                <AnimationOutputCardTile
                  activeBoardId={activeBoardId}
                  adding={addingCardId === card.id}
                  card={card}
                  key={card.id}
                  onAddToBoard={onAddToBoard}
                />
              ))}
            </Box>
          ) : null}
        </Stack>
      </CardContent>
    </Card>
  );
}

function AnimationOutputCardTile({
  activeBoardId,
  adding,
  card,
  onAddToBoard,
}: {
  activeBoardId: string;
  adding: boolean;
  card: AnimationOutputCard;
  onAddToBoard: (card: AnimationOutputCard) => void;
}) {
  const metadataTone = card.verification.metadata_valid ? "ok" : "warning";
  const previewTone = card.preview.available && card.verification.runtime_preview_verified ? "ok" : "warning";
  const addDisabled = !activeBoardId || adding;

  return (
    <Card variant="outlined">
      <CardContent>
        <Stack spacing={1.5}>
          <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
            <Stack direction="row" spacing={1.25} sx={{ minWidth: 0 }}>
              <Box sx={{ color: "text.secondary", pt: 0.25 }}>
                <AnimationOutlinedIcon />
              </Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                  {card.title}
                </Typography>
                <Typography color="text.secondary" variant="caption">
                  {card.source_kind} · {formatCreatedAt(card.created_at)}
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
              minHeight: 112,
              justifyContent: "center",
              p: 1.5,
            }}
          >
            <PreviewSummary preview={card.preview} />
          </Box>

          <Stack direction="row" flexWrap="wrap" gap={1}>
            <StatusChip label="visual reference only" tone={card.visual_reference_only ? "warning" : "error"} />
            <StatusChip
              label={card.structural_certification === false ? "not structurally certified" : "certification unknown"}
              tone="warning"
            />
            <StatusChip
              label={card.operator_review_required ? "operator review required" : "operator review unknown"}
              tone="warning"
            />
            <StatusChip label={card.verification.metadata_valid ? "metadata verified" : "metadata warning"} tone={metadataTone} />
            <StatusChip
              label={card.verification.runtime_preview_verified ? "preview verified" : "no verified preview"}
              tone={previewTone}
            />
            <Chip label={card.generation_mode ?? "mode unknown"} size="small" variant="outlined" />
          </Stack>

          <InfoPanel title="Timeline">
            <Typography variant="body2">{card.timeline.fps} FPS</Typography>
            <Typography variant="body2">
              Frames {card.timeline.start_frame}-{card.timeline.end_frame}
            </Typography>
            <Typography variant="body2">{card.timeline.frame_count ?? card.timeline.total_frames ?? "unknown"} total frames</Typography>
            <Typography variant="body2">{formatDuration(card.timeline.duration_seconds)}</Typography>
          </InfoPanel>

          <InfoPanel title="Summary">
            <Typography variant="body2">Tracks {card.summary.track_count}</Typography>
            <Typography variant="body2">Keyframes {card.summary.keyframe_count}</Typography>
            <Typography variant="body2">Segments {card.summary.segment_count}</Typography>
            <Typography variant="body2">Operations {card.summary.operation_count}</Typography>
          </InfoPanel>

          <ChipList label="target types" values={card.summary.target_types} />
          <ChipList label="target ids" values={card.summary.target_ids} />
          <ChipList label="properties" values={card.summary.properties} />
          <ChipList label="interpolations" values={card.summary.interpolations} />

          <InfoPanel title="Runtime paths">
            <PathLine label="metadata" value={card.relative_runtime_paths.metadata} />
            <PathLine label="report" value={card.relative_runtime_paths.report} />
            <PathLine label="preview frames" value={card.relative_runtime_paths.preview_frames} />
            <PathLine label="declared video preview" note="declared only" value={card.relative_runtime_paths.declared_video_preview} />
          </InfoPanel>

          <InfoPanel title="Verification">
            <Typography variant="body2">Metadata valid: {yesNo(card.verification.metadata_valid)}</Typography>
            <Typography variant="body2">Provenance not checked: {yesNo(!card.verification.provenance_checked)}</Typography>
            <Typography variant="body2">Preview report valid: {yesNo(card.verification.preview_report_valid)}</Typography>
            <Typography variant="body2">Runtime preview verified: {yesNo(card.verification.runtime_preview_verified)}</Typography>
            <Typography variant="body2">Errors: {card.verification.error_count}</Typography>
            <Typography variant="body2">Warnings: {card.verification.warning_count}</Typography>
          </InfoPanel>

          <Stack spacing={0.75}>
            <Button disabled={addDisabled} onClick={() => onAddToBoard(card)} size="small" variant="outlined">
              {adding ? "Adding" : "Add to board"}
            </Button>
            {!activeBoardId ? (
              <Typography color="text.secondary" variant="caption">
                Select a reference board first.
              </Typography>
            ) : (
              <Typography color="text.secondary" variant="caption">
                Adds an animation metadata reference only. No frame, video, metadata, or source asset is copied or modified.
              </Typography>
            )}
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}

function PreviewSummary({ preview }: { preview: AnimationOutputCard["preview"] }) {
  if (!preview.available) {
    return (
      <Stack alignItems="center" spacing={0.5}>
        <ImageNotSupportedOutlinedIcon color="disabled" fontSize="large" />
        <Typography color="text.secondary" variant="caption">
          No verified sampled-frame preview
        </Typography>
      </Stack>
    );
  }

  return (
    <Stack alignItems="center" spacing={0.5}>
      <AnimationOutlinedIcon color="action" fontSize="large" />
      <Typography fontWeight={800} variant="body2">
        Verified sampled PNG preview
      </Typography>
      <Typography color="text.secondary" variant="caption">
        {preview.frame_count ?? 0} frames · {preview.width ?? "unknown"} x {preview.height ?? "unknown"} ·{" "}
        {preview.format ?? "format unknown"}
      </Typography>
      <Typography color="text.secondary" sx={{ overflowWrap: "anywhere", textAlign: "center" }} variant="caption">
        first frame: {preview.first_frame_relative_path ?? "not reported"}
      </Typography>
    </Stack>
  );
}

function InfoPanel({ children, title }: { children: ReactNode; title: string }) {
  return (
    <Box
      sx={{
        bgcolor: "background.default",
        border: "1px solid rgba(145, 158, 171, 0.16)",
        borderRadius: 1,
        p: 1,
      }}
    >
      <Typography color="text.secondary" variant="caption">
        {title}
      </Typography>
      <Stack spacing={0.25}>{children}</Stack>
    </Box>
  );
}

function ChipList({ label, values }: { label: string; values: string[] }) {
  const visibleValues = values.slice(0, VISIBLE_CHIP_LIMIT);
  const remainingCount = values.length - visibleValues.length;
  return (
    <Stack spacing={0.75}>
      <Typography color="text.secondary" variant="caption">
        {label}
      </Typography>
      <Stack direction="row" flexWrap="wrap" gap={1}>
        {visibleValues.length > 0 ? (
          visibleValues.map((value) => <Chip key={value} label={value} size="small" variant="outlined" />)
        ) : (
          <Chip label="none reported" size="small" variant="outlined" />
        )}
        {remainingCount > 0 ? <Chip label={`+${remainingCount} more`} size="small" variant="outlined" /> : null}
      </Stack>
    </Stack>
  );
}

function PathLine({ label, note, value }: { label: string; note?: string; value: string | null }) {
  return (
    <Typography sx={{ overflowWrap: "anywhere" }} variant="body2">
      {label}: {value ?? "not reported"}
      {value && note ? ` (${note})` : ""}
    </Typography>
  );
}

function formatCreatedAt(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "invalid date";
  }
  return date.toLocaleString();
}

function formatDuration(value: number): string {
  if (!Number.isFinite(value) || value < 0) {
    return "duration unknown";
  }
  return `${value.toFixed(2)} seconds`;
}

function yesNo(value: boolean): string {
  return value ? "yes" : "no";
}

function hasUnsafeSafetyFlags(cardsResponse: AnimationOutputCardsResponse): boolean {
  const flags = cardsResponse.safety_flags;
  return (
    flags.read_only !== true ||
    flags.generation_triggered !== false ||
    flags.animation_execution_attempted !== false ||
    flags.preview_render_attempted !== false ||
    flags.runtime_assets_written !== false ||
    flags.runtime_assets_modified !== false ||
    flags.runtime_assets_deleted !== false ||
    flags.source_assets_modified !== false ||
    flags.external_process_started !== false ||
    flags.shell_execution !== false
  );
}
