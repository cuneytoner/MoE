# Reference Board Error Handling Polish

## What Was Polished

M34.34 adds the first practical hardening slice from the reference board hardening plan.

The polish covers:

- safer Gateway error responses for reference board routes
- clearer runtime-store errors for malformed or unavailable board data
- concise dashboard messages for reference board actions
- selected negative checks in the export regression script

No product features were added.

## Standard Error Shape

Reference board errors should use this JSON shape where possible:

```json
{
  "status": "error",
  "error": "error_code",
  "detail": "Human readable message."
}
```

The `detail` value must be safe for operators. It should not include Python tracebacks, absolute host paths, model paths, secrets, or raw internal exception text.

## Backend Error Codes

M34.34 standardizes these reference board error codes:

- `invalid_board_id`
- `reference_board_not_found`
- `reference_board_already_exists`
- `invalid_item_id`
- `reference_board_item_not_found`
- `output_card_not_found`
- `invalid_reference_board_payload`
- `reference_board_store_unavailable`
- `reference_board_malformed`
- `metadata_unavailable`
- `export_unavailable`

Malformed board JSON is converted to a controlled `reference_board_malformed` response instead of crashing the route.

Missing metadata remains non-fatal for export when the board item itself is valid. Export metadata summaries can report unavailable metadata.

## Dashboard Error Behavior

The dashboard now prefers safe Gateway error `detail` text for reference board calls.

Reference board action failures are labeled by action:

- create board
- board load
- add item
- remove item
- save note/tags
- export JSON
- export Markdown
- copy export content

Download links remain simple browser attachment links. The dashboard help text notes that browser download settings may block a download.

## Negative Regression Checks

`make reference-board-export-regression` still validates the happy path.

M34.34 adds selected negative checks:

- invalid board id on `export/json` returns a controlled non-success response
- missing board on `export/json` returns a controlled non-success response
- invalid board id on `download/markdown` returns a controlled non-success response

The script checks stable HTTP codes only for these narrow cases.

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

- full validation limit enforcement
- malformed store fixture regression
- dashboard end-to-end browser test
- ZIP/PDF export
- runtime export archive
- source asset bundle
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

Manual curl negative checks can inspect:

```text
GET /gateway/media/reference-boards/InvalidBoard/export/json
GET /gateway/media/reference-boards/missing-reference-board/export/json
GET /gateway/media/reference-boards/InvalidBoard/download/markdown
```

Expected behavior:

- JSON error shape is returned.
- No traceback is shown.
- No absolute host path is shown.
- Existing happy-path export/download regression still passes.
