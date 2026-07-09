# Reference Board Item Selection API

## What Was Implemented

M34.17 adds safe API endpoints to add and remove output cards as reference board items.

The API validates each selected item by resolving `card_id` through the existing output cards endpoint behavior.

M34.12 uses these endpoints from the dashboard `Reference Boards` and `Media Output Cards` sections.

M34.12.1 updates output cards to use relative-runtime-path based card ids, avoiding duplicate item references when files share the same basename in different folders.

M34.19 consumes item selection data in board detail cards, including item name, asset type, safety label, selected reason, tags, added timestamp, relative runtime path, and metadata availability.

M34.21 adds selected_reason/tags editing for board item references only.

## Endpoints

```text
POST /gateway/media/reference-boards/{board_id}/items
DELETE /gateway/media/reference-boards/{board_id}/items/{item_id}
```

## Add Request Example

```json
{
  "card_id": "image:moe_pergola_g3_beam_post_geometry_20260707_153843_00001_.png",
  "selected_reason": "Useful beam-post visual reference.",
  "tags": ["pergola", "beam-post"]
}
```

## Add Response Example

```json
{
  "status": "ok",
  "service": "gateway-reference-boards",
  "board": {
    "board_id": "api-test-board",
    "items": []
  },
  "item": {
    "item_id": "image-moe_pergola_g3_beam_post_geometry_20260707_153843_00001_png",
    "card_id": "image:moe_pergola_g3_beam_post_geometry_20260707_153843_00001_.png"
  }
}
```

## How Output Card Validation Works

The request may include only `card_id`, `selected_reason`, and optional tags.

The API resolves `card_id` through the output cards scan. Item fields such as `asset_type`, `name`, `relative_runtime_path`, `metadata_path`, and `safety_label` come from the output card, not from the request.

## Duplicate Behavior

Adding the same `card_id` to the same board returns:

```text
409 reference_board_item_exists
```

## Remove Behavior

Removing an item deletes only the item reference from the board JSON.

It does not delete image files, SVG files, metadata sidecars, or any generated asset.

## Safety Rules

- no arbitrary paths
- no absolute paths
- no arbitrary relative paths
- no asset copy/move/delete
- no source asset mutation
- no image generation
- no shell execution
- board JSON is the only runtime file updated

The dashboard UI must keep using `card_id`, `board_id`, and `item_id`; it must not construct item requests from source asset paths.

## What Is Not Implemented Yet

- drag/drop board UI
- asset copy/move/delete
- generation
- reference board detail view

Dashboard create/select/add/remove UI is implemented in M34.12.

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
CARD_ID="$(curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.type == "image") | .id' | head -n 1)"

echo "$CARD_ID"
```

### Run on PC-1
```bash
curl -fsS -X POST http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/items \
  -H 'Content-Type: application/json' \
  -d "{\"card_id\":\"${CARD_ID}\",\"selected_reason\":\"Useful visual reference from output cards.\",\"tags\":[\"api-test\",\"visual-reference\"]}" | jq .
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board | jq '.board.items'
```
