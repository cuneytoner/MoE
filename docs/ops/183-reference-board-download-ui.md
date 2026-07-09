# Reference Board Download UI

## What Was Implemented

M34.29 adds dashboard download actions for active reference board exports.

The dashboard now exposes response-only attachment downloads for JSON and Markdown reference board review artifacts. It does not create runtime export files, ZIP files, PDF files, copied source assets, or generated media.

## UI Behavior

When a reference board is selected in the dashboard, the board detail area shows:

- Download JSON
- Download Markdown

The existing Export JSON and Export Markdown buttons still open read-only panels. The new download buttons use Gateway attachment endpoints so the browser handles the file download.

## Endpoints Used

```text
GET /gateway/media/reference-boards/{board_id}/download/json
GET /gateway/media/reference-boards/{board_id}/download/markdown
```

## Why Board ID Is Used

Download URLs are built from the active board's `board_id` only.

The dashboard uses `encodeURIComponent(boardId)` through API URL helpers.

## Why Paths Are Not Used

Download URLs do not use:

- asset path
- `relative_runtime_path`
- `metadata_path`
- source asset path
- arbitrary filesystem path
- board title

The server controls the attachment filename through `Content-Disposition`.

## Safety Rules

- downloads are response-only review artifacts
- no runtime export files
- no source asset download
- no source asset copy
- no source asset move
- no source asset delete
- no source asset rename
- no generation trigger
- no ZIP download
- no PDF download
- no asset bundle download
- no arbitrary filesystem browsing
- no shell execution

## What Is Not Implemented Yet

- no ZIP download
- no PDF download
- no asset bundle download
- no source asset download
- no export history
- no runtime export archive

## How To Run And Review

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

Expected:

- Select a reference board.
- Download JSON button visible.
- Download Markdown button visible.
- Clicking each downloads an attachment.
- No source assets are copied, moved, deleted, or generated.
