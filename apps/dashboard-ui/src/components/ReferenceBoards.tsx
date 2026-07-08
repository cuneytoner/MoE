import { useState, type FormEvent } from "react";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import BookmarkAddedOutlinedIcon from "@mui/icons-material/BookmarkAddedOutlined";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  Divider,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import type { ReferenceBoard, ReferenceBoardCreateRequest, ReferenceBoardSummary } from "../types";
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
}: Props) {
  const [boardId, setBoardId] = useState("");
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

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

  return (
    <Card id="reference-boards">
      <CardHeader subheader="Curate output card references without copying source assets." title="Reference Boards" />
      <CardContent>
        <Stack spacing={2}>
          <Alert severity="info" variant="outlined">
            Reference boards store selected asset references only. They do not copy, move, delete, or approve source
            assets.
          </Alert>

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

                  <Divider />

                  {activeBoard.items.length === 0 ? (
                    <Typography color="text.secondary" variant="body2">
                      Select output cards below to add references to this board.
                    </Typography>
                  ) : null}

                  <Stack spacing={1}>
                    {activeBoard.items.map((item) => (
                      <Box
                        key={item.item_id}
                        sx={{
                          border: "1px solid rgba(145, 158, 171, 0.18)",
                          borderRadius: 1,
                          p: 1.5,
                        }}
                      >
                        <Stack spacing={1}>
                          <Stack alignItems="flex-start" direction="row" justifyContent="space-between" spacing={2}>
                            <Box sx={{ minWidth: 0 }}>
                              <Typography fontWeight={800} sx={{ overflowWrap: "anywhere" }} variant="body2">
                                {item.name}
                              </Typography>
                              <Typography color="text.secondary" sx={{ overflowWrap: "anywhere" }} variant="caption">
                                {item.relative_runtime_path}
                              </Typography>
                            </Box>
                            <StatusChip label={item.asset_type} tone="neutral" />
                          </Stack>
                          {item.selected_reason ? (
                            <Typography color="text.secondary" variant="body2">
                              {item.selected_reason}
                            </Typography>
                          ) : null}
                          {item.tags.length > 0 ? (
                            <Stack direction="row" flexWrap="wrap" gap={0.75}>
                              {item.tags.map((tag) => (
                                <Chip key={tag} label={tag} size="small" variant="outlined" />
                              ))}
                            </Stack>
                          ) : null}
                          <Box>
                            <Button
                              disabled={loading}
                              onClick={() => void onRemoveBoardItem(item.item_id)}
                              size="small"
                              startIcon={<RemoveCircleOutlineIcon />}
                              variant="outlined"
                            >
                              Remove from board
                            </Button>
                          </Box>
                        </Stack>
                      </Box>
                    ))}
                  </Stack>
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
    </Card>
  );
}
