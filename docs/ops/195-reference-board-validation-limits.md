# Reference Board Validation Limits

## What Was Implemented

M34.35 adds explicit validation limits for reference board create, add-item, and note/tag update flows.

The backend remains authoritative. The dashboard shows lightweight hints so operators can see the expected limits before submitting.

## Board Id Policy

`board_id` must follow these rules:

- required
- max 80 characters
- lowercase letters, numbers, dash, and underscore only
- no spaces
- no slash
- no dot-dot traversal
- no leading dot

Invalid board ids return a controlled `400` error.

## Title/Description Limits

Board title:

- required on create
- trimmed
- max 120 characters

Board description:

- optional
- trimmed
- max 500 characters

## selected_reason Limits

`selected_reason`:

- optional
- must be a string if provided
- trimmed
- empty string becomes not provided
- max 1000 characters

## Tag Limits

Tags:

- must be strings
- trimmed
- empty tags are rejected
- max 12 tags
- max 40 characters per tag
- allowed characters are letters, numbers, dash, underscore, and space
- duplicate tags are normalized by preserving the first occurrence

## Backend Error Response

Validation failures use the standard reference board error shape:

```json
{
  "status": "error",
  "error": "invalid_reference_board_payload",
  "detail": "Reference board item payload is invalid."
}
```

Invalid `board_id` failures continue to use:

```json
{
  "status": "error",
  "error": "invalid_board_id",
  "detail": "Invalid reference board id."
}
```

## Dashboard Hints

The dashboard shows simple helper text for:

- board id allowed characters and length
- title max length
- description max length
- selected reason max length
- tag count, length, and character policy

The dashboard also blocks obviously invalid tag edits before sending the request.

## Regression Checks

`make reference-board-export-regression` includes selected validation checks:

- invalid create `board_id` is rejected
- over-limit `selected_reason` patch is rejected
- too many tags patch is rejected

The checks use temporary files under `/tmp` and do not create persistent boards.

Validation limits protect incoming payloads before they are stored. M34.36 separately tests already-malformed runtime board files so broken on-disk JSON still returns controlled errors.

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP
- no PDF
- no source asset copy/move/delete
- no arbitrary filesystem browsing
- no stack traces shown to users
- no absolute host path leakage
- no shell execution

## What Is Not Implemented Yet

- store repair workflow
- dashboard end-to-end browser validation test
- ZIP/PDF export
- source asset bundles
- approval workflow
- generation workflow

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
bash -n scripts/reference-board-export-regression.sh
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
make reference-board-export-regression
```

Manual curl validation tests can check:

- invalid board id create
- over-limit selected reason patch
- too many tags patch

Expected:

- invalid validation payloads return controlled JSON errors
- no traceback is shown
- no absolute host path is shown
- happy-path export/download regression still passes
