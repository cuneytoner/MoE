# Reference Board Malformed Store Regression

## Purpose

M34.36 adds a safe regression script for malformed reference board runtime files.

The regression proves that a broken board JSON file does not crash Gateway reference board routes, does not expose Python tracebacks, and does not leak unsafe runtime paths through controlled error responses.

M34.37 defines future repair planning after malformed store detection.

## What The Script Creates

The script creates one intentionally malformed runtime test file:

```text
/home/cuneyt/MoE/runtime/reference-boards/malformed-regression-board.json
```

The file content is:

```text
{ bad json
```

The script removes that exact file before exit. It refuses to overwrite an existing file with the same board id.

## Runtime Location

Reference board runtime data stays outside the source repo:

```text
/home/cuneyt/MoE/runtime/reference-boards
```

Do not place malformed fixture files, board stores, generated media, export artifacts, or logs inside the repo.

## Endpoints Checked

The regression calls:

- `GET /gateway/media/reference-boards`
- `GET /gateway/media/reference-boards/{board_id}`
- `GET /gateway/media/reference-boards/{board_id}/export/json`
- `GET /gateway/media/reference-boards/{board_id}/download/markdown`

The list endpoint must not return HTTP 500 and must not expose a traceback.

The read, export, and download endpoints must return non-2xx controlled JSON errors.

## Error Safety Checks

The script checks malformed board error responses for:

- no `Traceback`
- no `/home/cuneyt`
- no `/mnt`
- no `/media`
- JSON shape with `status`, `error`, and `detail`

The list endpoint may include normal runtime-root metadata in the current API response. For that endpoint, the regression focuses on no HTTP 500 and no traceback.

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
make reference-board-malformed-store-regression
```

### Run on PC-1 with custom board id
```bash
BOARD_ID=malformed-regression-board make reference-board-malformed-store-regression
```

### Run on PC-1 with custom runtime dir
```bash
REFERENCE_BOARD_RUNTIME_DIR=/home/cuneyt/MoE/runtime/reference-boards make reference-board-malformed-store-regression
```

## Expected Output

```text
Reference board malformed store regression OK
BOARD_ID=malformed-regression-board
GATEWAY_API_URL=http://127.0.0.1:8100
REFERENCE_BOARD_RUNTIME_DIR=/home/cuneyt/MoE/runtime/reference-boards
```

## What It Does Not Do

- does not create source repo fixtures
- does not create runtime export files
- does not create ZIP/PDF artifacts
- does not copy, move, delete, approve, or generate source assets
- does not repair malformed boards
- does not delete any board except the exact temporary malformed test file

## Troubleshooting

If the regression fails:

- confirm `gateway-api` is running
- confirm the runtime reference board directory exists
- confirm no real board already uses the selected `BOARD_ID`
- inspect the script failure message
- verify the malformed test file was removed
- run `git status --short` to confirm no runtime artifacts entered the repo
