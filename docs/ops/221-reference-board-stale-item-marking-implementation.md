# Reference Board Stale Item Marking Implementation

## What Was Implemented

M34.48 extends `scripts/reference-board-store-repair.sh` with a guarded stale item marking mode:

```text
MODE=mark-stale-items
```

The mode detects stale reference board items and marks board JSON entries only when `APPLY=1` and an existing backup is present.

M34.49 adds dedicated regression coverage for `MODE=mark-stale-items`.

M34.50 documents safe operator flow for stale item marking.

M34.51 includes stale item marking in the full repair workflow summary.

M34.52 displays stale markers in JSON/Markdown exports.

## Supported Mode

Supported stale marking mode:

```text
MODE=mark-stale-items
```

Existing modes remain available:

- `repair-schema`
- `remove-duplicate-items`

## Stale Detection Rules

An item is stale when one or more of these checks fail:

- `relative_runtime_path` is missing, empty, not a string, absolute, or contains traversal.
- `relative_runtime_path` points outside allowlisted runtime output roots.
- `relative_runtime_path` points to a missing output file under an allowlisted runtime output root.
- `card_id` is missing, empty, not a string, or no longer matches the expected output-card id.
- `asset_type` is missing, empty, or not a string.
- `metadata_path`, when present, is empty, not a string, absolute, contains traversal, points outside allowlisted runtime roots, or points to a missing metadata file.

The allowlisted runtime output roots are:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
/home/cuneyt/MoE/runtime/pergola/drawings
/home/cuneyt/MoE/runtime/drawings
```

If a path is outside those roots, the report sets `stale_check_limited` instead of scanning arbitrary locations.

## Mark-Not-Remove Policy

This mode does not delete board items, source assets, metadata sidecars, output cards, or generated files.

When applying, it only adds or updates these board item fields:

- `stale: true`
- `stale_reason`
- `stale_checked_at`

Existing stale markers on currently non-stale items are left unchanged in this milestone.

## Dry-Run Behavior

Dry-run is the default:

```text
APPLY=0
```

Dry-run reports stale items, proposed marks, skipped marks, and safety flags. It does not modify the board file.

## APPLY=1 Behavior

With `APPLY=1`, the CLI:

- requires an existing backup when `REQUIRE_BACKUP=1`
- marks stale board item references only
- writes only the reference board JSON file
- updates `updated_at` when the board changes and the field already exists
- writes atomically through a temporary file and rename
- does not rewrite if no stale marker changes are needed

## Backup Requirement

Before applying stale marks, run:

```bash
BOARD_ID=api-test-board make reference-board-store-backup
```

The repair CLI requires a matching backup:

```text
reference-board-{BOARD_ID}-*.json.bak
```

## Report Fields

Stale marking mode reports:

- `stale_items`
- `stale_reason`
- `stale_checked_at`
- `stale_check_limited`
- `asset_exists`
- `metadata_exists`
- `output_card_exists`
- `proposed_stale_marks`
- `applied_stale_marks`
- `skipped_stale_marks`
- `board_file_modified`
- `repair_applied`

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no metadata sidecar modification
- no output card deletion
- no stale item deletion
- no source asset recreation
- no metadata invention
- no Gateway/dashboard repair button
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
```

### Dry-run stale marking
```bash
BOARD_ID=api-test-board MODE=mark-stale-items make reference-board-store-repair
jq . /tmp/moe-reference-board-store-repair-report.json
```

### Apply only after backup and review
```bash
BOARD_ID=api-test-board make reference-board-store-backup
BOARD_ID=api-test-board MODE=mark-stale-items APPLY=1 make reference-board-store-repair
```

## What Is Not Implemented Yet

- stale item deletion
- source asset repair
- metadata sidecar repair
- stale marker cleanup
- dashboard repair button
- backend repair endpoint
- all-board stale marking
- stale item regression suite
