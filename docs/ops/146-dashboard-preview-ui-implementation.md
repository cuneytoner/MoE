# Dashboard Preview UI Implementation

## What Was Implemented

M34.14 updates the dashboard output cards UI so image cards can display real previews from the safe Gateway preview endpoint.

Drawing and SVG cards keep the placeholder UI.

Metadata detail view is added after preview UI in M34.15.

## Endpoint Used

```text
GET /gateway/media/output-preview/{card_id}
```

## Why card_id Is Used

The UI builds preview URLs only from `card.id`:

```text
/gateway/media/output-preview/{card_id}
```

The UI does not build preview URLs from `path`, `metadata_path`, or `relative_runtime_path`.

## Image Preview Behavior

Image cards request previews only when:

- `card.type == "image"`
- `card.preview_available == true`

The preview image fits the card thumbnail area and preserves a stable layout.

## SVG Placeholder Behavior

`drawing_svg` cards do not request the preview endpoint. They keep the placeholder icon until a future SVG sanitization policy and UI milestone exist.

## Error Fallback

If an image preview fails to load, the card falls back to the placeholder state and shows:

```text
preview unavailable
```

The dashboard should keep rendering the card metadata even when preview loading fails.

## Safety Rules

- no SVG preview
- no PDF preview
- no arbitrary filesystem browsing
- no preview URL from paths
- no download button
- no delete/move/rename buttons
- no generation button
- no shell action
- no service controls

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq '.status, .service, (.cards | length), .cards[0]'
```

### Open in browser
```text
http://127.0.0.1:8500
```

Expected:

- image cards show real preview image
- `drawing_svg` cards show placeholder
- no delete/move/rename/generate buttons

## How To Inspect Dashboard

Open the dashboard and find `Media Output Cards`.

Confirm image cards show compact previews and drawing cards retain placeholder icons. If a preview fails, confirm the fallback text appears and the dashboard remains usable.

## What Is Not Implemented Yet

- No SVG previews.
- No PDF previews.
- No preview modal.
- No compare view.
- No reference-board preview UI.
- No metadata detail drawer.
