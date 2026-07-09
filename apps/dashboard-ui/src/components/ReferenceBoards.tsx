import { useState, type FormEvent } from "react";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import ArticleOutlinedIcon from "@mui/icons-material/ArticleOutlined";
import BookmarkAddedOutlinedIcon from "@mui/icons-material/BookmarkAddedOutlined";
import ContentCopyOutlinedIcon from "@mui/icons-material/ContentCopyOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import InsertDriveFileOutlinedIcon from "@mui/icons-material/InsertDriveFileOutlined";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
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
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import {
  fetchOutputCardMetadata,
  fetchReferenceBoardJsonExport,
  fetchReferenceBoardMarkdownExport,
  gatewayBaseUrl,
  referenceBoardJsonDownloadUrl,
  referenceBoardMarkdownDownloadUrl,
} from "../api";
import type {
  OutputCardMetadataResponse,
  ReferenceBoard,
  ReferenceBoardCreateRequest,
  ReferenceBoardItem,
  ReferenceBoardSummary,
  ReferenceBoardUpdateItemRequest,
} from "../types";
import { StatusChip } from "./StatusChip";

type Props = {
  actionMessage: string;
  activeBoard: ReferenceBoard | null;
  boards: ReferenceBoardSummary[];
  error: string;
  loading: boolean;
  onCreateBoard: (request: ReferenceBoardCreateRequest) => Promise<void>;
  onRemoveBoardItem: (itemId: string) => Promise<void>;
  onSelectBoard: (boardId: string) => Promise<void>;
  onUpdateBoardItem: (itemId: string, request: ReferenceBoardUpdateItemRequest) => Promise<void>;
};

export function ReferenceBoards({
  actionMessage,
  activeBoard,
  boards,
  error,
  loading,
  onCreateBoard,
  onRemoveBoardItem,
  onSelectBoard,
  onUpdateBoardItem,
}: Props) {
  const [boardId, setBoardId] = useState("");
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [metadataItem, setMetadataItem] = useState<ReferenceBoardItem | null>(null);
  const [metadataResponse, setMetadataResponse] = useState<OutputCardMetadataResponse | null>(null);
  const [metadataLoading, setMetadataLoading] = useState(false);
  const [metadataError, setMetadataError] = useState("");
  const [exportDialog, setExportDialog] = useState<ReferenceBoardExportDialogState | null>(null);
  const [exportLoading, setExportLoading] = useState(false);
  const [exportError, setExportError] = useState("");
  const [copyMessage, setCopyMessage] = useState("");

  async function submitCreate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await onCreateBoard({
      board_id: boardId.trim(),
      description: description.trim() || null,
      title: title.trim(),
    });
    setBoardId("");
    setTitle("");
    setDescription("");
  }

  async function openMetadata(item: ReferenceBoardItem) {
    setMetadataItem(item);
    setMetadataResponse(null);
    setMetadataError("");
    setMetadataLoading(true);
    try {
      setMetadataResponse(await fetchOutputCardMetadata(item.card_id));
    } catch (err) {
      setMetadataError(err instanceof Error ? err.message : "unknown metadata error");
    } finally {
      setMetadataLoading(false);
    }
  }

  async function openExport(format: "json" | "markdown") {
    if (!activeBoard) {
      return;
    }
    setExportDialog(null);
    setExportError("");
    setCopyMessage("");
    setExportLoading(true);
    try {
      if (format === "json") {
        const data = await fetchReferenceBoardJsonExport(activeBoard.board_id);
        setExportDialog({
          content: JSON.stringify(data, null, 2),
          format,
          title: "JSON Export",
        });
      } else {
        const content = await fetchReferenceBoardMarkdownExport(activeBoard.board_id);
        setExportDialog({
          content,
          format,
          title: "Markdown Export",
        });
      }
    } catch (err) {
      setExportError(err instanceof Error ? err.message : "unknown reference board export error");
    } finally {
      setExportLoading(false);
    }
  }

  async function copyExportContent(content: string) {
    setCopyMessage("");
    if (typeof navigator === "undefined" || !navigator.clipboard) {
      setCopyMessage("Clipboard unavailable.");
      return;
    }
    try {
      await navigator.clipboard.writeText(content);
      setCopyMessage("Copied");
    } catch (err) {
      setCopyMessage(err instanceof Error ? err.message : "Unable to copy export.");
    }
  }

  return (
    <Card id="reference-boards">
      <CardHeader subheader="Curate output card references without copying source assets." title="Reference Boards" />
      <CardContent>
        <Stack spacing={2}>
          {error ? (
            <Alert severity="warning" variant="outlined">
              Reference boards unavailable: {error}
            </Alert>
          ) : null}

          {actionMessage ? (
            <Alert severity={actionMessage.toLowerCase().includes("already") ? "info" : "success"} variant="outlined">
              {actionMessage}
            </Alert>
          ) : null}

          <Box
            sx={{
              display: "grid",
              gap: 2,
              gridTemplateColumns: { xs: "1fr", lg: "minmax(260px, 0.8fr) minmax(0, 1.2fr)" },
            }}
          >
            <Stack spacing={2}>
              <Box component="form" onSubmit={(event) => void submitCreate(event)}>
                <Stack spacing={1.5}>
                  <Typography fontWeight={800} variant="body2">
                    Create board
                  </Typography>
                  <TextField
                    disabled={loading}
                    label="board_id"
                    onChange={(event) => setBoardId(event.target.value)}
                    size="small"
                    value={boardId}
                  />
                  <TextField
                    disabled={loading}
                    label="title"
                    onChange={(event) => setTitle(event.target.value)}
                    size="small"
                    value={title}
                  />
                  <TextField
                    disabled={loading}
                    label="description"
                    minRows={2}
                    multiline
                    onChange={(event) => setDescription(event.target.value)}
                    size="small"
                    value={description}
                  />
                  <Button
                    disabled={loading || boardId.trim() === "" || title.trim() === ""}
                    startIcon={<AddCircleOutlineIcon />}
                    type="submit"
                    variant="contained"
                  >
                    Create board
                  </Button>
                </Stack>
              </Box>

              <Divider />

              <Stack spacing={1}>
                <Typography fontWeight={800} variant="body2">
                  Boards
                </Typography>
                {boards.length === 0 ? (
                  <Typography color="text.secondary" variant="body2">
                    No reference boards yet.
                  </Typography>
                ) : null}
                {boards.map((board) => {
                  const selected = activeBoard?.board_id === board.board_id;
                  return (
                    <Button
                      color={selected ? "primary" : "inherit"}
                      disabled={loading}
                      key={board.board_id}
                      onClick={() => void onSelectBoard(board.board_id)}
                      startIcon={<BookmarkAddedOutlinedIcon />}
                      sx={{ justifyContent: "flex-start", textAlign: "left" }}
                      variant={selected ? "contained" : "outlined"}
                    >
                      <Box sx={{ minWidth: 0 }}>
                        <Typography sx={{ overflowWrap: "anywhere" }} variant="body2">
                          {board.title}
                        </Typography>
                        <Typography color={selected ? "inherit" : "text.secondary"} variant="caption">
                          {board.item_count} items
                        </Typography>
                      </Box>
                    </Button>
                  );
                })}
              </Stack>
            </Stack>

            <Box
              sx={{
                border: "1px solid rgba(145, 158, 171, 0.24)",
                borderRadius: 1,
                minHeight: 260,
                p: 2,
              }}
            >
              {activeBoard ? (
                <Stack spacing={2}>
                  <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
                    <Box sx={{ minWidth: 0 }}>
                      <Typography fontWeight={900} sx={{ overflowWrap: "anywhere" }} variant="h6">
                        {activeBoard.title}
                      </Typography>
                      <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
                        {activeBoard.board_id}
                      </Typography>
                    </Box>
                    <StatusChip label={activeBoard.safety_label} tone="warning" />
                  </Stack>

                  {activeBoard.description ? (
                    <Typography color="text.secondary" variant="body2">
                      {activeBoard.description}
                    </Typography>
                  ) : null}

                  <Stack direction="row" flexWrap="wrap" gap={1}>
                    <Chip label={`${activeBoard.items.length} items`} size="small" variant="outlined" />
                    <Chip label={`updated ${new Date(activeBoard.updated_at).toLocaleString()}`} size="small" variant="outlined" />
                  </Stack>

                  <Stack spacing={1.5}>
                    <Box>
                      <Typography color="text.secondary" variant="body2">
                        Exports open read-only review panels. Downloads save response-only review artifacts.
                      </Typography>
                      <Typography color="text.secondary" variant="caption">
                        These actions do not copy, move, delete, approve, or generate source assets.
                      </Typography>
                    </Box>

                    <Stack spacing={1}>
                      <Typography fontWeight={800} variant="body2">
                        Review exports
                      </Typography>
                      <Stack direction="row" flexWrap="wrap" gap={1}>
                        <Button
                          disabled={loading || exportLoading}
                          onClick={() => void openExport("json")}
                          startIcon={<ArticleOutlinedIcon />}
                          variant="outlined"
                        >
                          Export JSON
                        </Button>
                        <Button
                          disabled={loading || exportLoading}
                          onClick={() => void openExport("markdown")}
                          startIcon={<ArticleOutlinedIcon />}
                          variant="outlined"
                        >
                          Export Markdown
                        </Button>
                        {exportLoading ? (
                          <Stack alignItems="center" direction="row" spacing={1}>
                            <CircularProgress size={18} />
                            <Typography color="text.secondary" variant="body2">
                              Loading export.
                            </Typography>
                          </Stack>
                        ) : null}
                      </Stack>
                    </Stack>

                    <Stack spacing={1}>
                      <Typography fontWeight={800} variant="body2">
                        Downloads
                      </Typography>
                      <Stack direction="row" flexWrap="wrap" gap={1}>
                        <Button
                          component="a"
                          disabled={loading}
                          href={referenceBoardJsonDownloadUrl(activeBoard.board_id)}
                          startIcon={<FileDownloadOutlinedIcon />}
                          variant="outlined"
                        >
                          Download JSON
                        </Button>
                        <Button
                          component="a"
                          disabled={loading}
                          href={referenceBoardMarkdownDownloadUrl(activeBoard.board_id)}
                          startIcon={<FileDownloadOutlinedIcon />}
                          variant="outlined"
                        >
                          Download Markdown
                        </Button>
                      </Stack>
                    </Stack>

                    {exportError ? (
                      <Alert severity="warning" variant="outlined">
                        Export unavailable: {exportError}
                      </Alert>
                    ) : null}
                  </Stack>

                  <Divider />

                  {activeBoard.items.length === 0 ? (
                    <Typography color="text.secondary" variant="body2">
                      No items yet. Select an output card and use Add to board.
                    </Typography>
                  ) : null}

                  <Box
                    sx={{
                      display: "grid",
                      gap: 1.5,
                      gridTemplateColumns: { xs: "1fr", xl: "repeat(2, minmax(0, 1fr))" },
                    }}
                  >
                    {activeBoard.items.map((item) => (
                      <ReferenceBoardItemCard
                        item={item}
                        key={item.item_id}
                        loading={loading}
                        onRemoveBoardItem={onRemoveBoardItem}
                        onUpdateBoardItem={onUpdateBoardItem}
                        onViewMetadata={openMetadata}
                      />
                    ))}
                  </Box>
                </Stack>
              ) : (
                <Stack alignItems="center" justifyContent="center" spacing={1} sx={{ minHeight: 220, textAlign: "center" }}>
                  <BookmarkAddedOutlinedIcon color="disabled" fontSize="large" />
                  <Typography color="text.secondary" variant="body2">
                    Select or create a reference board to review selected output card references.
                  </Typography>
                </Stack>
              )}
            </Box>
          </Box>
        </Stack>
      </CardContent>
      <ReferenceBoardMetadataDialog
        error={metadataError}
        item={metadataItem}
        loading={metadataLoading}
        metadata={metadataResponse?.metadata ?? null}
        onClose={() => {
          setMetadataItem(null);
          setMetadataResponse(null);
          setMetadataError("");
        }}
      />
      <ReferenceBoardExportDialog
        copyMessage={copyMessage}
        exportState={exportDialog}
        onClose={() => {
          setExportDialog(null);
          setCopyMessage("");
          setExportError("");
        }}
        onCopy={copyExportContent}
      />
    </Card>
  );
}

type ReferenceBoardExportDialogState = {
  content: string;
  format: "json" | "markdown";
  title: string;
};

function ReferenceBoardItemCard({
  item,
  loading,
  onRemoveBoardItem,
  onUpdateBoardItem,
  onViewMetadata,
}: {
  item: ReferenceBoardItem;
  loading: boolean;
  onRemoveBoardItem: (itemId: string) => Promise<void>;
  onUpdateBoardItem: (itemId: string, request: ReferenceBoardUpdateItemRequest) => Promise<void>;
  onViewMetadata: (item: ReferenceBoardItem) => void;
}) {
  const [previewFailed, setPreviewFailed] = useState(false);
  const [editing, setEditing] = useState(false);
  const [reasonDraft, setReasonDraft] = useState(item.selected_reason ?? "");
  const [tagsDraft, setTagsDraft] = useState(item.tags.join(", "));
  const [editError, setEditError] = useState("");
  const shouldShowImagePreview = item.asset_type === "image" && !previewFailed;
  const previewUrl = `${gatewayBaseUrl()}/gateway/media/output-preview/${encodeURIComponent(item.card_id)}`;

  function startEditing() {
    setReasonDraft(item.selected_reason ?? "");
    setTagsDraft(item.tags.join(", "));
    setEditError("");
    setEditing(true);
  }

  async function saveNote() {
    const tags = Array.from(
      new Set(
        tagsDraft
          .split(",")
          .map((tag) => tag.trim())
          .filter(Boolean),
      ),
    );
    setEditError("");
    try {
      await onUpdateBoardItem(item.item_id, {
        selected_reason: reasonDraft.trim() || null,
        tags,
      });
      setEditing(false);
    } catch (err) {
      setEditError(err instanceof Error ? err.message : "Unable to save board note.");
    }
  }

  return (
    <Box
      sx={{
        border: "1px solid rgba(145, 158, 171, 0.2)",
        borderRadius: 1,
        p: 1.5,
      }}
    >
      <Stack spacing={1.25}>
        <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
          <Stack direction="row" spacing={1.25} sx={{ minWidth: 0 }}>
            <Box sx={{ color: item.asset_type === "image" ? "primary.main" : "text.secondary", pt: 0.25 }}>
              {item.asset_type === "image" ? <ImageOutlinedIcon /> : <ArticleOutlinedIcon />}
            </Box>
            <Box sx={{ minWidth: 0 }}>
              <Typography fontWeight={900} sx={{ overflowWrap: "anywhere" }} variant="body2">
                {item.name}
              </Typography>
              <Typography color="text.secondary" variant="caption">
                added {new Date(item.added_at).toLocaleString()}
              </Typography>
            </Box>
          </Stack>
          <StatusChip label={item.asset_type} tone="neutral" />
        </Stack>

        <Box
          sx={{
            alignItems: "center",
            bgcolor: "background.default",
            border: "1px solid rgba(145, 158, 171, 0.24)",
            borderRadius: 1,
            display: "flex",
            height: 132,
            justifyContent: "center",
            overflow: "hidden",
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
          ) : item.asset_type === "image" ? (
            <Stack alignItems="center" spacing={0.5}>
              <ImageOutlinedIcon color="disabled" fontSize="large" />
              <Typography color="text.secondary" variant="caption">
                preview unavailable
              </Typography>
            </Stack>
          ) : (
            <Stack alignItems="center" spacing={0.5}>
              <InsertDriveFileOutlinedIcon color="disabled" fontSize="large" />
              <Typography color="text.secondary" variant="caption">
                SVG placeholder
              </Typography>
            </Stack>
          )}
        </Box>

        <Stack direction="row" flexWrap="wrap" gap={0.75}>
          <StatusChip label={item.safety_label} tone={safetyTone(item.safety_label)} />
          {item.tags.map((tag, index) => (
            <Chip key={`${tag}-${index}`} label={tag} size="small" variant="outlined" />
          ))}
        </Stack>

        {editing ? (
          <Stack spacing={1}>
            {editError ? (
              <Alert severity="warning" variant="outlined">
                {editError}
              </Alert>
            ) : null}
            <TextField
              disabled={loading}
              label="selected_reason"
              minRows={2}
              multiline
              onChange={(event) => setReasonDraft(event.target.value)}
              size="small"
              value={reasonDraft}
            />
            <TextField
              disabled={loading}
              helperText="Comma-separated board tags."
              label="tags"
              onChange={(event) => setTagsDraft(event.target.value)}
              size="small"
              value={tagsDraft}
            />
            <Stack direction="row" flexWrap="wrap" gap={1}>
              <Button disabled={loading} onClick={() => void saveNote()} size="small" variant="contained">
                Save note
              </Button>
              <Button disabled={loading} onClick={() => setEditing(false)} size="small" variant="outlined">
                Cancel
              </Button>
            </Stack>
          </Stack>
        ) : item.selected_reason ? (
          <Typography color="text.secondary" variant="body2">
            {item.selected_reason}
          </Typography>
        ) : (
          <Typography color="text.secondary" variant="body2">
            No board note yet.
          </Typography>
        )}

        <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
          {item.relative_runtime_path}
        </Typography>

        <Stack direction="row" flexWrap="wrap" gap={1}>
          {!editing ? (
            <Button disabled={loading} onClick={startEditing} size="small" variant="outlined">
              Edit board note
            </Button>
          ) : null}
          {item.metadata_path ? (
            <Button onClick={() => onViewMetadata(item)} size="small" variant="outlined">
              View metadata
            </Button>
          ) : null}
          <Button
            disabled={loading}
            onClick={() => void onRemoveBoardItem(item.item_id)}
            size="small"
            startIcon={<RemoveCircleOutlineIcon />}
            variant="outlined"
          >
            Remove from board
          </Button>
        </Stack>
      </Stack>
    </Box>
  );
}

function ReferenceBoardMetadataDialog({
  error,
  item,
  loading,
  metadata,
  onClose,
}: {
  error: string;
  item: ReferenceBoardItem | null;
  loading: boolean;
  metadata: Record<string, unknown> | null;
  onClose: () => void;
}) {
  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open={item !== null}>
      <DialogTitle>Reference item metadata</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ pb: 1 }}>
          {item ? (
            <Box>
              <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                {item.name}
              </Typography>
              <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
                {item.card_id}
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

          {metadata ? <ReferenceMetadataDetails assetType={item?.asset_type ?? ""} metadata={metadata} /> : null}
        </Stack>
      </DialogContent>
    </Dialog>
  );
}

function ReferenceBoardExportDialog({
  copyMessage,
  exportState,
  onClose,
  onCopy,
}: {
  copyMessage: string;
  exportState: ReferenceBoardExportDialogState | null;
  onClose: () => void;
  onCopy: (content: string) => Promise<void>;
}) {
  const canCopy = typeof navigator !== "undefined" && Boolean(navigator.clipboard);
  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open={exportState !== null}>
      <DialogTitle>{exportState?.title ?? "Reference board export"}</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ pb: 1 }}>
          <Box
            component="pre"
            sx={{
              bgcolor: "background.default",
              border: "1px solid rgba(145, 158, 171, 0.24)",
              borderRadius: 1,
              fontFamily: "monospace",
              fontSize: 12,
              maxHeight: 420,
              overflow: "auto",
              p: 1.5,
              whiteSpace: "pre-wrap",
              wordBreak: "break-word",
            }}
          >
            {exportState?.content ?? ""}
          </Box>
          <Typography color="text.secondary" variant="caption">
            {exportState?.format === "json" ? "Formatted JSON response." : "Raw Markdown text response."}
          </Typography>
          {copyMessage ? (
            <Alert severity={copyMessage.toLowerCase().includes("copied") ? "success" : "warning"} variant="outlined">
              {copyMessage}
            </Alert>
          ) : null}
        </Stack>
      </DialogContent>
      <DialogActions>
        {canCopy && exportState ? (
          <Button
            onClick={() => void onCopy(exportState.content)}
            startIcon={<ContentCopyOutlinedIcon />}
            variant="outlined"
          >
            Copy
          </Button>
        ) : null}
        <Button onClick={onClose} variant="contained">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function ReferenceMetadataDetails({ assetType, metadata }: { assetType: string; metadata: Record<string, unknown> }) {
  const fields =
    assetType === "image"
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
          <ReferenceMetadataField field={field} key={field} value={metadata[field]} />
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

function ReferenceMetadataField({ field, value }: { field: string; value: unknown }) {
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
