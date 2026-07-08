# Reference Board Safe Runtime Store

## What Was Implemented

M34.16 adds the first safe runtime storage helper for reference board JSON files.

This milestone does not add public Gateway reference-board API endpoints or dashboard selection UI.

## Runtime Folder

Reference boards are stored under:

```text
/home/cuneyt/MoE/runtime/reference-boards
```

## Helper Module

```text
apps/gateway-api/app/reference_boards.py
```

The helper provides board id validation, safe runtime path construction, JSON read/write helpers, empty board construction, and basic schema validation.

## JSON-only Policy

Boards are JSON files only.

Each board id maps to:

```text
/home/cuneyt/MoE/runtime/reference-boards/{board_id}.json
```

## board_id Safety Rules

Allowed characters:

- lowercase letters
- numbers
- dash
- underscore

Blocked:

- empty board ids
- spaces
- slashes
- backslashes
- dot-dot traversal
- hidden path patterns
- uppercase letters
- arbitrary absolute paths

## What Is Blocked

- source asset mutation
- generated asset copy/move/delete/rename
- image generation
- PDF or DXF generation
- shell execution
- arbitrary filesystem browsing
- model files
- secrets
- board JSON larger than `256 KiB`

## Smoke Test

The smoke test creates a runtime-only board:

```text
/home/cuneyt/MoE/runtime/reference-boards/smoke-test-board.json
```

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-store-smoke-test
```

### Run on PC-1
```bash
find /home/cuneyt/MoE/runtime/reference-boards \
  -maxdepth 1 -type f -name '*.json' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

### Run on PC-1
```bash
jq . /home/cuneyt/MoE/runtime/reference-boards/smoke-test-board.json
```

## What Is Not Implemented Yet

- No public reference-board API endpoint.
- No dashboard reference-board UI.
- No output-card selection UI.
- No board item add/remove API.
- No asset copying.
- No board export workflow.

## Next Steps

- M34.11 Reference Board API Implementation.
- M34.12 Reference Board UI Implementation.
- M34.17 Reference Board Item Selection API.
