import ViewInArOutlinedIcon from "@mui/icons-material/ViewInArOutlined";
import { Alert, Box, Button, Card, CardContent, CardHeader, Chip, Stack, Typography } from "@mui/material";
import type { ThreeDOutputCard, ThreeDOutputCardsResponse } from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  activeBoardId: string;
  addingCardId: string;
  cardsResponse: ThreeDOutputCardsResponse | null;
  error: string;
  loading: boolean;
  onAddToBoard: (card: ThreeDOutputCard) => void;
};

const MAX_VISIBLE_CARDS = 12;

export function ThreeDOutputCards({ activeBoardId, addingCardId, cardsResponse, error, loading, onAddToBoard }: Props) {
  const cards = cardsResponse?.cards ?? [];
  const visibleCards = cards.slice(0, MAX_VISIBLE_CARDS);
  const metadataMissing = cardsResponse?.metadata_dir_available === false;
  const invalidCount = cardsResponse?.invalid_count ?? 0;

  return (
    <Card id="three-d-output-cards">
      <CardHeader
        subheader="Read-only view of guarded Blender outputs and metadata verification."
        title="3D Output Cards"
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

          <Alert severity="info" variant="outlined">
            Adds a metadata reference only. No 3D asset is copied or modified.
          </Alert>

          {error ? (
            <Alert severity="warning" variant="outlined">
              3D output cards unavailable: {error}
            </Alert>
          ) : null}

          {!error && loading && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              Loading 3D output cards.
            </Typography>
          ) : null}

          {!error && !loading && metadataMissing ? (
            <Alert severity="info" variant="outlined">
              3D metadata directory is not available yet.
            </Alert>
          ) : null}

          {!error && !loading && !metadataMissing && cards.length === 0 ? (
            <Typography color="text.secondary" variant="body2">
              No verified 3D output metadata reported yet.
            </Typography>
          ) : null}

          {!error && invalidCount > 0 ? (
            <Alert severity="warning" variant="outlined">
              {invalidCount} invalid metadata sidecar(s) were skipped.
            </Alert>
          ) : null}

          {!error && cardsResponse && cardsResponse.warnings.length > 0 ? (
            <Alert severity="warning" variant="outlined">
              <Stack spacing={0.5}>
                {cardsResponse.warnings.slice(0, 5).map((warning) => (
                  <Typography key={warning} variant="body2">
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
                <ThreeDOutputCardTile
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

function ThreeDOutputCardTile({
  activeBoardId,
  adding,
  card,
  onAddToBoard,
}: {
  activeBoardId: string;
  adding: boolean;
  card: ThreeDOutputCard;
  onAddToBoard: (card: ThreeDOutputCard) => void;
}) {
  const verificationTone = card.verification.valid ? "ok" : "warning";
  const addDisabled = !activeBoardId || adding;

  return (
    <Card variant="outlined">
      <CardContent>
        <Stack spacing={1.5}>
          <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
            <Stack direction="row" spacing={1.25} sx={{ minWidth: 0 }}>
              <Box sx={{ color: "text.secondary", pt: 0.25 }}>
                <ViewInArOutlinedIcon />
              </Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                  {card.asset_name}
                </Typography>
                <Typography color="text.secondary" variant="caption">
                  {card.asset_category} · {new Date(card.created_at).toLocaleString()}
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
            }}
          >
            <Stack alignItems="center" spacing={0.5}>
              <ViewInArOutlinedIcon color="disabled" fontSize="large" />
              <Typography color="text.secondary" variant="caption">
                preview placeholder
              </Typography>
            </Stack>
          </Box>

          <Stack direction="row" flexWrap="wrap" gap={1}>
            <StatusChip label={card.safety_label} tone="warning" />
            <StatusChip label={card.verification.valid ? "verified" : "verification warning"} tone={verificationTone} />
            <Chip
              label={card.structural_certification === false ? "Not structurally certified" : "Certification unknown"}
              size="small"
              variant="outlined"
            />
            <Chip
              label={card.operator_review_required === true ? "Operator review required" : "Operator review unknown"}
              size="small"
              variant="outlined"
            />
            <Chip label={card.generation_mode ?? "mode unknown"} size="small" variant="outlined" />
          </Stack>

          <Stack direction="row" flexWrap="wrap" gap={1}>
            {(card.formats.length > 0 ? card.formats : ["no existing formats"]).map((format) => (
              <Chip key={format} label={format} size="small" variant="outlined" />
            ))}
          </Stack>

          <Box
            sx={{
              bgcolor: "background.default",
              border: "1px solid rgba(145, 158, 171, 0.16)",
              borderRadius: 1,
              p: 1,
            }}
          >
            <Typography color="text.secondary" variant="caption">
              Verification
            </Typography>
            <Typography variant="body2">
              existing {card.verification.existing_count} · missing {card.verification.missing_count} · errors{" "}
              {card.verification.error_count}
            </Typography>
            {card.verification.errors.slice(0, 2).map((message) => (
              <Typography color="text.secondary" key={message} sx={{ overflowWrap: "anywhere" }} variant="caption">
                {message}
              </Typography>
            ))}
          </Box>

          <Stack spacing={0.5}>
            <Typography color="text.secondary" variant="caption">
              metadata
            </Typography>
            <Typography sx={{ overflowWrap: "anywhere" }} variant="body2">
              {card.metadata_path}
            </Typography>
          </Stack>

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
                Adds a metadata reference only. No 3D asset is copied or modified.
              </Typography>
            )}
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
}
