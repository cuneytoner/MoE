# Reference Board UI CORS + Card ID Fix

## Problem Observed

M34.12 made the reference-board UI visible, but browser `Add to board` failed from:

```text
http://127.0.0.1:8500
```

to:

```text
http://127.0.0.1:8100
```

The browser console showed a blocked CORS preflight for reference-board `POST` requests.

The React console also showed duplicate child key warnings for output cards with the same filename in different runtime folders.

## CORS Issue

Gateway CORS allowed the dashboard origins but only allowed `GET`.

Reference-board UI needs preflight support for create, add, and remove operations.

## Duplicate Key Issue

Output card ids were based on:

```text
{type}:{filename}
```

That was not unique when two generated outputs shared the same basename in different runtime folders.

## Fixes Implemented

- Gateway CORS now allows local dashboard `POST`, `DELETE`, and `OPTIONS` requests.
- Output card ids now use the relative runtime path.
- Preview and metadata endpoints still resolve `card_id` through the output-card scan.
- Preview and metadata routes accept slash-containing card ids without treating them as filesystem paths.

M34.19 keeps unique item/card keys in board detail rendering by using `item.item_id` for board item cards and `card.id` for output cards.

## CORS Allowed Origins

```text
http://127.0.0.1:8500
http://localhost:8500
```

Allowed methods:

```text
GET
POST
DELETE
OPTIONS
```

Allowed headers:

```text
Content-Type
Accept
Origin
Authorization
```

## New Card ID Strategy

Card ids now use:

```text
{type}:{relative_runtime_path}
```

Examples:

```text
image:media/outputs/images/flux-first/moe_x.png
drawing_svg:pergola/drawings/top_plan.svg
```

The id does not include an absolute path.

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[].id' \
  | sort | uniq -d
```

Expected: no output.

### Run on PC-1
```bash
curl -fsS -X OPTIONS http://127.0.0.1:8100/gateway/media/reference-boards/smoke-test-board/items \
  -H 'Origin: http://127.0.0.1:8500' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Content-Type' \
  -D /tmp/moe-reference-board-cors-headers
```

Expected: preflight succeeds and the response headers allow the dashboard origin.

### Open in browser
```text
http://127.0.0.1:8500/#media
```

Select a board, click `Add to board`, and confirm no CORS error or duplicate key warning appears.

## Safety Notes

- No image generation is triggered.
- No source asset is copied, moved, deleted, renamed, or approved.
- No arbitrary filesystem browsing is added.
- Card ids use relative runtime paths only.
- Preview and metadata endpoints continue to resolve ids through allowlisted output cards.
