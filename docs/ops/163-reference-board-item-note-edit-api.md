# Reference Board Item Note Edit API

## What Was Implemented

M34.21 adds a safe Gateway endpoint and dashboard UI for editing reference board item notes.

The update changes only the board JSON file. It does not update source assets, generated images, SVG drawings, or metadata sidecars.

## Endpoint

```text
PATCH /gateway/media/reference-boards/{board_id}/items/{item_id}
```

## Editable Fields

```json
{
  "selected_reason": "Updated reason text.",
  "tags": ["tag-a", "tag-b"]
}
```

Fields are optional, but at least one editable field must be present.

## Blocked Fields

The endpoint does not allow updates to:

- `item_id`
- `card_id`
- `asset_type`
- `name`
- `relative_runtime_path`
- `metadata_path`
- `safety_label`
- `added_at`

## Request Example

```json
{
  "selected_reason": "Updated from PATCH smoke test.",
  "tags": ["updated", "curated"]
}
```

## Response Example

```json
{
  "status": "ok",
  "service": "gateway-reference-boards",
  "board": {
    "board_id": "api-test-board",
    "items": []
  },
  "item": {
    "item_id": "image-example",
    "selected_reason": "Updated from PATCH smoke test.",
    "tags": ["updated", "curated"]
  }
}
```

## Safety Rules

- Update only reference-board JSON.
- Do not update source image files.
- Do not update SVG files.
- Do not update metadata sidecars.
- Do not trigger generation.
- Do not accept arbitrary paths.
- Do not execute shell commands.
- Do not add asset delete, move, or rename controls.

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
ITEM_ID="$(curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board \
  | jq -r '.board.items[0].item_id')"

curl -fsS -X PATCH "http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/items/${ITEM_ID}" \
  -H 'Content-Type: application/json' \
  -d '{"selected_reason":"Updated from PATCH smoke test.","tags":["updated","curated"]}' | jq .
```

Expected:

- Response status is `ok`.
- `selected_reason` is updated.
- `tags` are updated.
- `card_id` is unchanged.
- `relative_runtime_path` is unchanged.
