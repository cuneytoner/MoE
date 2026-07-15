# Reference Board Stale Item Regression

## What Was Implemented

M34.49 adds `scripts/reference-board-stale-item-regression.sh`, a controlled regression for:

```text
MODE=mark-stale-items
```

The regression creates one temporary fixture board, verifies dry-run reporting, verifies `APPLY=1` is rejected without backup, creates a backup, applies stale marks, validates the marked board, checks mark-not-remove behavior, and cleans up.

## Test Fixture Behavior

The fixture board is created at:

```text
/home/cuneyt/MoE/runtime/reference-boards/stale-item-regression-board.json
```

The fixture uses unique item ids and card ids. It includes:

- one stale item with missing `relative_runtime_path`
- one stale item with absolute `relative_runtime_path`
- one stale item with dot-dot traversal in `relative_runtime_path`
- one stale item with unsafe absolute `metadata_path`
- one shape-control item that stays structurally valid without asset creation

It uses fake runtime output paths for stale checks and does not create source asset files or metadata sidecars.

## Dry-Run Stale Checks

Dry-run runs:

```bash
BOARD_ID=stale-item-regression-board MODE=mark-stale-items scripts/reference-board-store-repair.sh
```

It verifies:

- report type is `reference_board_store_repair`
- mode is `mark-stale-items`
- `apply` is `false`
- board file is not modified
- repair is not applied
- `stale_items` is not empty
- `proposed_stale_marks` is not empty
- the board file still has no stale markers

## APPLY=1 Without Backup Check

The regression removes matching stale regression backups, then runs:

```bash
BOARD_ID=stale-item-regression-board MODE=mark-stale-items APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- command exits non-zero
- report includes `backup_required_missing`
- board file is not modified
- stale markers are not added

## Backup Then APPLY=1 Check

The regression creates a backup:

```bash
BOARD_ID=stale-item-regression-board scripts/reference-board-store-backup.sh
```

Then it applies stale marking:

```bash
BOARD_ID=stale-item-regression-board MODE=mark-stale-items APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- board file is modified
- repair is applied
- `applied_stale_marks` is not empty
- stale items receive `stale`, `stale_reason`, and `stale_checked_at`

## Mark-Not-Remove Verification

The regression verifies that all fixture items remain in the board after stale marking.

It does not delete board items, source assets, metadata sidecars, output cards, or generated files.

## Validate After Marking

After applying stale marks, the regression runs:

```bash
BOARD_ID=stale-item-regression-board scripts/reference-board-store-validate.sh
```

The fixture is shaped so stale markers can be validated after marking. Marked stale path defects may appear as validation warnings, but the regression requires no validation errors.

## Cleanup Behavior

The cleanup trap removes only:

- `/home/cuneyt/MoE/runtime/reference-boards/stale-item-regression-board.json`
- `/home/cuneyt/MoE/runtime/reference-boards/backups/reference-board-stale-item-regression-board-*.json.bak`

It does not remove directories.

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no real board mutation
- no `api-test-board` mutation
- no metadata sidecar modification
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-stale-item-regression
```

Expected:

```text
Reference board stale item regression OK
```
