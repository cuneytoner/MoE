# Reference Board Store Repair CLI Implementation

## What Was Implemented

M34.42 adds `scripts/reference-board-store-repair.sh`, the first guarded write-capable reference board store tool.

Only `repair-schema` mode is supported. The script is dry-run by default and does not modify board files unless `APPLY=1` is set and an existing backup is found.

M34.43 adds dedicated repair regression coverage with a temporary fixture board.

Duplicate item removal is intentionally not implemented in M34.42 and is planned separately in M34.44.

M34.46 extends the repair CLI with `remove-duplicate-items` mode.

## Dry-Run Default

Default behavior:

```text
APPLY=0
MODE=repair-schema
```

Dry-run reports proposed actions and skipped actions. It does not modify the board file.

## APPLY=1 Requirement

Board file modification requires:

```text
APPLY=1
```

If `APPLY` is not `1`, the script cannot write the board file.

## Backup Requirement

With `APPLY=1`, the script requires an existing backup by default:

```text
REQUIRE_BACKUP=1
```

The backup must match:

```text
reference-board-{BOARD_ID}-*.json.bak
```

under:

```text
/home/cuneyt/MoE/runtime/reference-boards/backups
```

Run `make reference-board-store-backup` before applying repair.

## Supported Mode

Current supported modes:

- `repair-schema`
- `remove-duplicate-items`

Stale item deletion, source asset repair, metadata repair, restore, or all-board repair is not implemented.

## Safe Repairs Allowed

`repair-schema` may:

- trim `title` if it is a string
- trim `description` if it is a string
- trim `selected_reason` if it is a string
- normalize tags by trimming whitespace
- remove empty tags
- remove duplicate tags while preserving first occurrence
- set missing `items` to `[]`
- add missing board `safety_label` as `visual_reference_only`
- add missing item `tags` as `[]`
- add missing item `selected_reason` as `""`

## Unsafe Repairs Denied

The script does not:

- invent `board_id`
- invent `title`
- invent `created_at` or `updated_at`
- invent `item_id`
- invent `card_id`
- invent `relative_runtime_path`
- invent `asset_type`
- invent source assets
- invent metadata
- remove items
- mark stale items

## Atomic Write Behavior

When `APPLY=1` and changes are needed, the script:

- writes repaired JSON to a temporary file in the same directory
- uses stable JSON indentation and sorted keys
- renames the temporary file into place
- updates `updated_at` only when the board is changed and the field already exists
- does not rewrite the board when no changes are needed
- does not overwrite backup files

## Report Schema

The script writes:

```json
{
  "schema_version": "1.0",
  "report_type": "reference_board_store_repair",
  "created_at": "timestamp",
  "runtime_dir": "runtime reference board directory",
  "board_id": "board id",
  "mode": "repair-schema",
  "apply": false,
  "backup_required": true,
  "backup_found": true,
  "board_file": "board file path",
  "findings": [],
  "proposed_actions": [],
  "applied_actions": [],
  "skipped_actions": [],
  "safety_flags": {
    "source_assets_modified": false,
    "metadata_modified": false,
    "board_file_modified": false,
    "backup_created": false,
    "repair_applied": false,
    "generation_triggered": false
  }
}
```

## Exit Codes

- `0`: success, no fatal errors
- `1`: validation or repair findings exist but no fatal error
- `2`: invalid CLI usage
- `3`: board missing
- `4`: backup required but missing
- `5`: repair failed

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no metadata sidecar modification
- no repair without `APPLY=1`
- no apply without an existing backup
- no duplicate item deletion
- no stale item deletion
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1 dry-run
```bash
cd ~/DiskD/Projects/MoE/codebase
BOARD_ID=api-test-board make reference-board-store-repair
```

### Show report
```bash
jq . /tmp/moe-reference-board-store-repair-report.json
```

### Run backup first
```bash
BOARD_ID=api-test-board make reference-board-store-backup
```

### Apply only after review
```bash
BOARD_ID=api-test-board APPLY=1 make reference-board-store-repair
```

## What Is Not Implemented Yet

- duplicate item deletion
- stale item deletion
- source asset repair
- metadata repair
- restore
- all-board repair
- dashboard repair button
- backend repair endpoint
- repair regression suite
