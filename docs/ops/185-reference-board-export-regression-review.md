# Reference Board Export Regression Review

## What The Regression Script Checks

M34.30 adds `scripts/reference-board-export-regression.sh`, a safe smoke-test script for the complete reference board export and download flow.

M34.31 is UI polish only; backend regression remains covered by the script.

M34.33 identifies future regression expansion cases.

M34.34 extends regression with selected negative error checks.

M34.35 extends regression with selected validation checks.

The script checks:

- JSON export works
- Markdown export works
- JSON download works
- Markdown download works
- download headers are correct
- safety flags are correct
- exported content does not leak obvious host paths
- downloaded JSON is valid
- downloaded Markdown includes expected review sections
- no runtime export files are created

## Endpoints Covered

```text
GET /gateway/media/reference-boards/{board_id}/export/json
GET /gateway/media/reference-boards/{board_id}/export/markdown
GET /gateway/media/reference-boards/{board_id}/download/json
GET /gateway/media/reference-boards/{board_id}/download/markdown
```

## Safety Checks

The regression script verifies:

- `safety.review_only == true`
- `safety.source_assets_copied == false`
- `safety.source_assets_deleted == false`
- `safety.generation_triggered == false`
- no `/home/cuneyt`, `/mnt`, or `/media` strings appear in export/download content
- no files are created under `/home/cuneyt/MoE/runtime/reference-boards/exports`

Temporary files are created only under `/tmp` and removed when the script exits.

## Header Checks

The script checks download headers:

- JSON download `Content-Type` includes `application/json`
- Markdown download `Content-Type` includes `text/markdown`
- download endpoints include `Content-Disposition: attachment`
- JSON filename begins with `reference-board-{BOARD_ID}-` and ends with `.json`
- Markdown filename begins with `reference-board-{BOARD_ID}-` and ends with `.md`

## Content Checks

JSON content must be valid and match the reference-board review pack safety contract.

Markdown content must include:

- `Reference Board Review Pack`
- `Safety`
- `Items`
- `Selected reason`

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
make reference-board-export-regression
```

### Run on PC-1 with custom board
```bash
BOARD_ID=api-test-board make reference-board-export-regression
```

## Expected Output

```text
Reference board export regression OK
BOARD_ID=api-test-board
GATEWAY_API_URL=http://127.0.0.1:8100
```

## What Is Not Tested

- dashboard button clicks
- browser download prompts
- ZIP/PDF export
- source asset downloads
- image generation
- visual rendering of the dashboard

## Troubleshooting

If the script fails:

- confirm `gateway-api` is running
- confirm the board exists
- confirm `jq`, `curl`, and `grep` are available
- inspect the failure message
- rerun with `BOARD_ID=<board_id>` for a known board

The script is intentionally read-only against Gateway export/download endpoints.
