# Output Card Metadata Detail API

## What Was Implemented

M34.15 adds a read-only Gateway endpoint for output card metadata sidecars.

The endpoint returns safe JSON metadata only for cards resolved through the existing output-cards allowlisted scan.

M34.12.1 changes output card ids to `{type}:{relative_runtime_path}`. The metadata endpoint continues to resolve by `card_id` through the output-card scan.

M34.19 reuses this card_id-based metadata endpoint from reference board item cards.

## Endpoint

```text
GET /gateway/media/output-card-metadata/{card_id}
```

## Safety Rules

- Resolve by `card_id` only.
- Do not accept absolute paths.
- Do not accept relative paths.
- Do not browse arbitrary folders.
- Do not execute shell commands.
- Do not trigger generation.
- Do not edit metadata.
- Do not delete, move, or rename assets.

## Card-id Based Resolution

The endpoint first resolves `card_id` through:

```text
GET /gateway/media/output-cards
```

It then reads only the matching card sidecar from `metadata_path`.

Card ids may include relative runtime path separators after M34.12.1. The endpoint still treats the value as an opaque card id and does not use it as a filesystem path.

The metadata sidecar must be the same-basename `.json` file next to the known asset.

## Metadata Size Limit

Metadata files are limited to:

```text
128 KiB
```

Files larger than that are blocked by safety policy.

## JSON Parse Behavior

Invalid JSON returns `metadata_invalid`.

Missing metadata returns `metadata_unavailable`.

Unsafe metadata paths return `metadata_blocked`.

## What Is Blocked

- hidden files
- hidden folders
- non-JSON metadata
- metadata outside allowlisted runtime roots
- sidecars that do not match the card asset basename
- model files
- arbitrary path input

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.metadata_available == true) | .id' | head -n 1
```

### Run on PC-1
```bash
CARD_ID="$(curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[] | select(.metadata_available == true) | .id' | head -n 1)"

curl -fsS "http://127.0.0.1:8100/gateway/media/output-card-metadata/${CARD_ID}" | jq .
```
