# Reference Board Store Validate CLI Implementation

## What Was Implemented

M34.40 adds `scripts/reference-board-store-validate.sh`, a read-only CLI for validating reference board runtime JSON files.

The script can validate one board with `BOARD_ID` or all direct `*.json` board files under the runtime reference board directory.

Validation remains read-only; M34.41 adds separate backup CLI.

Validation should be run before M34.42 repair-schema.

M34.43 uses the validate CLI after repair regression.

## Read-Only Behavior

The validator:

- reads reference board JSON files
- does not modify board files
- does not create backups
- does not repair data
- does not copy, move, delete, or read source assets
- does not trigger generation
- writes only the validation report to `REPORT_PATH`

## Env Vars

- `REFERENCE_BOARD_RUNTIME_DIR`, default `/home/cuneyt/MoE/runtime/reference-boards`
- `BOARD_ID`, default empty for all boards
- `REPORT_PATH`, default `/tmp/moe-reference-board-store-validate-report.json`

`BOARD_ID` must follow the safe board id policy: lowercase letters, numbers, dash, and underscore only.

## Validation Checks

The validator checks:

- runtime dir exists
- board file exists when `BOARD_ID` is set
- JSON parses
- top-level object exists
- `schema_version` exists
- `board_id` exists and matches filename
- `title` exists/string
- `description` is string if present
- `created_at` exists/string
- `updated_at` exists/string
- `safety_label` exists/string
- `items` exists and is array/list
- each item has `item_id`
- each item has `card_id`
- each item has `asset_type`
- each item has `name`
- each item has `relative_runtime_path`
- each item has `selected_reason`
- each item has `tags` list
- each item has `safety_label`
- each item has `added_at`
- duplicate `item_id`
- duplicate `card_id`
- `relative_runtime_path` is relative and has no traversal
- review fields do not contain obvious host paths
- `selected_reason` is within limit
- tags are within count, length, and character limits

Existing internal sidecar fields such as `metadata_path` are not treated as source asset reads or modified by this validator.

## Report Schema

The report uses:

```json
{
  "schema_version": "1.0",
  "report_type": "reference_board_store_validation",
  "created_at": "timestamp",
  "runtime_dir": "runtime reference board directory",
  "board_id": "board id or null",
  "checked_count": 0,
  "valid_count": 0,
  "invalid_count": 0,
  "findings": [],
  "safety_flags": {
    "read_only": true,
    "source_assets_modified": false,
    "board_files_modified": false,
    "repair_applied": false,
    "backup_created": false,
    "generation_triggered": false
  }
}
```

The report is local operator diagnostics and may include the runtime board directory and board file path. It must not include source asset contents or copy source assets.

## Exit Codes

- `0`: all checked boards valid
- `1`: validation findings exist
- `2`: invalid CLI usage or runtime dir missing

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no board file modification
- no repair
- no backup
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-store-validate
```

### Run on PC-1 for one board
```bash
cd ~/DiskD/Projects/MoE/codebase
BOARD_ID=api-test-board make reference-board-store-validate
```

### Show report
```bash
jq . /tmp/moe-reference-board-store-validate-report.json
```

## What Is Not Implemented Yet

- backup mode
- repair mode
- schema repair
- duplicate removal
- stale item marking
- restore
- dashboard validation button
- backend validation endpoint
