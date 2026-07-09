# Reference Board JSON Export Implementation

## What Was Implemented

M34.23 adds the first safe response-only JSON export endpoint for reference boards.

The endpoint returns a review pack JSON response. It does not create runtime export files, ZIP files, PDF files, Markdown files, or copied media assets.

M34.24 reuses the JSON review pack data for Markdown output.

M34.25 exposes JSON export through dashboard UI.

JSON download is planned as a future response-only attachment endpoint.

M34.28 adds response-only JSON download attachment endpoint.

## Endpoint

```text
GET /gateway/media/reference-boards/{board_id}/export/json
```

## Export Shape

The response follows the planned reference board review pack shape:

```text
schema_version
export_type
exported_at
board
items
safety
```

`export_type` is:

```text
reference_board_review_pack
```

## Metadata Summary Rules

Each item includes `metadata_summary`.

Allowed metadata summary fields are:

- source
- script
- workflow
- model_name
- model_family
- prompt
- seed
- width
- height
- steps
- drawing_kind
- geometry
- units
- project
- notes

If metadata is unavailable, invalid, blocked, or the output card is missing, `metadata_summary` reports `available=false` and a reason.

## Path Handling Rules

The export includes `relative_runtime_path`.

The export does not include:

- absolute asset paths
- absolute metadata paths
- source root absolute paths
- model paths
- arbitrary client-provided paths

Metadata summaries filter path-like and secret-looking strings.

## Safety Rules

- response-only JSON
- review artifact only
- no export files created
- no ZIP
- no PDF
- no Markdown output file
- no source asset copy/move/delete/rename
- no metadata sidecar mutation
- no generation trigger
- no shell execution
- no arbitrary filesystem browsing

## What Is Not Implemented Yet

- no ZIP export
- no download action
- no controlled copy mode

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/json | jq .
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/json \
  | jq '.export_type, .board.board_id, .board.item_count, .safety'
```

Expected:

- `export_type` is `reference_board_review_pack`.
- `safety.source_assets_copied` is `false`.
- `safety.source_assets_deleted` is `false`.
- `safety.generation_triggered` is `false`.
- Obvious absolute host paths are excluded.
