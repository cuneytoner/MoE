# Output Preview API Implementation

## What Was Implemented

M34.13 adds the first safe read-only output preview endpoint for image output cards.

The endpoint resolves a `card_id` through the existing output-cards allowlisted scan before serving any bytes.

M34.14 consumes this endpoint in the dashboard UI for image cards.

M34.12.1 changes output card ids to `{type}:{relative_runtime_path}`. The preview endpoint continues to resolve by `card_id` through the output-card scan.

M34.19 reuses this card_id-based image preview endpoint from reference board item cards.

## Endpoint

```text
GET /gateway/media/output-preview/{card_id}
```

## Supported Asset Types

Initial support is image-only:

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`

## Blocked Asset Types

- `drawing_svg`
- `.svg`
- `.pdf`
- `.gguf`
- `.safetensors`
- `.pt`
- `.pth`
- `.ckpt`
- hidden files
- files in hidden folders
- files outside allowlisted runtime roots

## Safety Policy

- no arbitrary absolute paths
- no relative path input
- no `..` traversal
- no model files
- no SVG serving yet
- no shell execution
- no generation trigger
- no delete, move, or rename
- no asset mutation

## How card_id Resolution Works

The preview endpoint accepts only `card_id`.

Card ids may include relative runtime path separators after M34.12.1. The endpoint still treats the value as an opaque card id and does not use it as a filesystem path.

The server scans the same allowlisted runtime folders used by:

```text
GET /gateway/media/output-cards
```

If the card id does not match a known output card, the endpoint returns `preview_unavailable`.

If the card exists but is not an image preview card, the endpoint returns `preview_unavailable`.

If the resolved file fails safety validation, the endpoint returns `preview_blocked`.

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.type == "image") | .id' | head -n 1
```

### Run on PC-1
```bash
IMAGE_CARD_ID="$(curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.type == "image") | .id' | head -n 1)"

curl -fsS "http://127.0.0.1:8100/gateway/media/output-preview/${IMAGE_CARD_ID}" \
  -o /tmp/moe-output-preview-test

file /tmp/moe-output-preview-test
```

### Run on PC-1
```bash
SVG_CARD_ID="$(curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.type == "drawing_svg") | .id' | head -n 1)"

curl -i "http://127.0.0.1:8100/gateway/media/output-preview/${SVG_CARD_ID}"
```

## What Is Not Implemented Yet

- No SVG preview serving.
- No PDF preview serving.
- No thumbnail generation.
- No download action.
- No preview modal.

## Next Steps

- M34.14 Dashboard Preview UI Implementation.
- Later SVG preview policy and sanitization if needed.
- Later compare view and reference board preview reuse.
