# Reference Board Markdown Export Implementation

## What Was Implemented

M34.24 adds a safe response-only Markdown export endpoint for reference boards.

The endpoint derives Markdown from the JSON review pack data. It does not create runtime export files, ZIP files, PDF files, copied media assets, or dashboard export UI.

## Endpoint

```text
GET /gateway/media/reference-boards/{board_id}/export/markdown
```

## Response Content Type

```text
text/markdown; charset=utf-8
```

## Markdown Sections

The Markdown response includes:

- `Reference Board Review Pack` title
- Board metadata
- Safety flags
- Item sections
- selected_reason
- tags
- relative_runtime_path
- metadata summary

## Metadata Summary Rules

Markdown metadata is derived from the JSON review pack metadata summary.

Known fields may include:

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
- units
- project
- geometry summary
- notes

Geometry dictionaries render as fenced JSON blocks.

## Path Handling Rules

Markdown includes relative runtime references only.

The endpoint does not include:

- absolute host paths
- metadata_path absolute paths
- image embeds
- SVG embeds
- arbitrary file links
- model paths

## Safety Rules

- response-only Markdown
- no export files
- no ZIP
- no PDF
- no source asset copy/move/delete/rename
- no generation trigger
- no shell execution
- no arbitrary filesystem browsing
- no dashboard export UI yet

## What Is Not Implemented Yet

- no dashboard export UI
- no export download flow
- no ZIP export
- no PDF export
- no controlled asset copy mode

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/markdown
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/markdown \
  | grep -E "Reference Board Review Pack|Selected reason|Safety|generation"
```
