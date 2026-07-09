# Reference Board Detail View

## What Was Implemented

M34.19 improves the dashboard `Reference Boards` section so selected board items render as useful detail cards.

The detail view remains reference-only. It does not copy, move, delete, rename, approve, or generate source assets.

M34.21 adds selected_reason/tags editing for board item references only.

The detail view prepares human-readable board state for future exports.

## UI Behavior

When a board is active, the dashboard shows:

- board title
- `board_id`
- description
- item count
- `safety_label`
- `updated_at`
- reference-only safety note

Empty boards show:

```text
No items yet. Select an output card and use Add to board.
```

## Board Detail Header

The header identifies the active board and shows the current item count and latest update timestamp.

The dashboard also shows:

```text
Reference boards store references only. Removing an item does not delete the source asset.
```

## Item Cards

Each board item card shows:

- item name
- asset type
- `safety_label`
- `selected_reason`
- tags
- `added_at`
- `relative_runtime_path`
- `View metadata` when metadata is available
- `Remove from board`

React keys use:

- `board.board_id` for board list entries
- `item.item_id` for board item cards
- `card.id` for output cards

## Preview Behavior

Image board items request previews through:

```text
GET /gateway/media/output-preview/{card_id}
```

The UI builds the preview URL from `item.card_id` only.

It does not use `relative_runtime_path` or `metadata_path` as a fetch URL.

If an image preview fails, the item card shows:

```text
preview unavailable
```

## SVG Placeholder Behavior

`drawing_svg` items show a placeholder.

The dashboard does not request SVG previews and does not serve SVG content.

## Metadata Behavior

Board item metadata uses:

```text
GET /gateway/media/output-card-metadata/{card_id}
```

The UI calls the metadata endpoint with `item.card_id` only.

It does not fetch metadata by `metadata_path`.

## Remove-from-board Safety

`Remove from board` removes only the item reference from the board JSON.

It does not delete source images, SVG files, metadata sidecars, or generated assets.

## What Is Not Implemented Yet

- No drag/drop ordering.
- No `selected_reason` editing.
- No board export.
- No compare view.
- No asset copy/move/delete.
- No generation button.
- No arbitrary file picker.
- No SVG direct preview.

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards | jq .
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

Expected:

- Active board detail visible.
- Board items render as detail cards.
- Image board item shows preview.
- `drawing_svg` board item shows placeholder.
- `View metadata` uses card_id endpoint.
- `Remove from board` removes only item reference.

## How To Review In Browser

1. Open the dashboard.
2. Select a reference board.
3. Add an image output card to the board if no image item is present.
4. Add a `drawing_svg` output card to the board if no drawing item is present.
5. Confirm image items show previews.
6. Confirm drawing items show placeholders.
7. Click `View metadata` on an item with metadata.
8. Click `Remove from board` and confirm the source asset remains in runtime output cards.
