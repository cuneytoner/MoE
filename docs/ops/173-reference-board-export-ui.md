# Reference Board Export UI

## What Was Implemented

M34.25 adds dashboard export actions for the active reference board.

The UI fetches JSON or Markdown export content from Gateway and shows it in a read-only dashboard dialog. It does not create files on disk, download files, copy source assets, move assets, delete assets, approve assets, or trigger generation.

## UI Behavior

When a reference board is selected in the dashboard, the board detail area shows:

- Export JSON
- Export Markdown

Each button loads the active board export by `board_id` only.

## APIs Used

```text
GET /gateway/media/reference-boards/{board_id}/export/json
GET /gateway/media/reference-boards/{board_id}/export/markdown
```

The dashboard uses `encodeURIComponent(boardId)` for the route value.

It does not build export URLs from:

- asset path
- `relative_runtime_path`
- `metadata_path`
- arbitrary user-provided filesystem paths

## JSON Export Panel

Export JSON opens a read-only panel with formatted JSON:

```text
JSON.stringify(data, null, 2)
```

The panel is for review only.

## Markdown Export Panel

Export Markdown opens a read-only panel with the raw Markdown text returned by Gateway.

The dashboard does not render embedded images or SVG from Markdown.

## Copy Behavior

If browser clipboard access is available, the panel shows a Copy button.

Copy copies the currently displayed export text to the clipboard. It does not write a file or create a runtime export artifact.

Download buttons are deferred until later milestones implement the M34.26 plan.

## Safety Rules

- export actions are review artifacts only
- no source asset copy
- no source asset move
- no source asset delete
- no source asset rename
- no source asset approval
- no image generation
- no ZIP export
- no PDF export
- no download-to-file
- no arbitrary filesystem browsing
- no shell execution

## What Is Not Implemented Yet

- no browser download action
- no Markdown download implementation
- no JSON download implementation
- no ZIP export
- no PDF export
- no controlled asset copy mode
- no export history

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
- Export JSON button visible.
- Export Markdown button visible.
- JSON export opens read-only formatted panel.
- Markdown export opens read-only text panel.
- No source assets are copied, moved, deleted, or generated.
