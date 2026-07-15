# Reference Board Duplicate Item Repair Regression

## What Was Implemented

M34.47 adds `scripts/reference-board-duplicate-item-repair-regression.sh`, a controlled regression for `MODE=remove-duplicate-items`.

The regression creates one temporary fixture board, verifies dry-run reporting, verifies `APPLY=1` is rejected without backup, creates a backup, applies duplicate removal, validates the repaired board, checks preserve-first behavior, and cleans up.

## Test Fixture Behavior

The script creates:

```text
/home/cuneyt/MoE/runtime/reference-boards/duplicate-repair-regression-board.json
```

The fixture includes:

- duplicate `card_id`
- duplicate `item_id`
- duplicate `relative_runtime_path`
- a unique item that must remain untouched
- selected reason and tag differences to exercise conflict reporting

The fixture uses fake relative paths only and does not create source asset files.

## Dry-Run Duplicate Checks

The regression runs:

```text
BOARD_ID=duplicate-repair-regression-board MODE=remove-duplicate-items scripts/reference-board-store-repair.sh
```

It verifies:

- report type is `reference_board_store_repair`
- mode is `remove-duplicate-items`
- `apply` is false
- `board_file_modified` is false
- `repair_applied` is false
- `duplicate_groups` is not empty
- `proposed_removals` is not empty
- duplicate items remain in the board file after dry-run

## APPLY=1 Without Backup Check

The regression deletes matching fixture backups, then runs:

```text
BOARD_ID=duplicate-repair-regression-board MODE=remove-duplicate-items APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- the command exits non-zero
- `backup_required_missing` is reported
- the board file still contains duplicates

## Backup Then APPLY=1 Check

The regression runs:

```text
BOARD_ID=duplicate-repair-regression-board scripts/reference-board-store-backup.sh
BOARD_ID=duplicate-repair-regression-board MODE=remove-duplicate-items APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- a backup is created
- duplicate removals are applied
- `board_file_modified` is true
- `repair_applied` is true
- `applied_removals` is not empty

## Preserve-First Verification

After repair, the regression verifies:

- first occurrence of duplicate `item_id` remains
- first occurrence of duplicate `card_id` remains
- first occurrence of duplicate `relative_runtime_path` remains
- later duplicate items are removed
- the unique item remains

## Validate After Repair

After `APPLY=1`, the regression runs:

```text
BOARD_ID=duplicate-repair-regression-board scripts/reference-board-store-validate.sh
```

Expected:

- validation report type is `reference_board_store_validation`
- validation findings are empty

## Cleanup Behavior

The script removes only:

- `/home/cuneyt/MoE/runtime/reference-boards/duplicate-repair-regression-board.json`
- `/home/cuneyt/MoE/runtime/reference-boards/backups/reference-board-duplicate-repair-regression-board-*.json.bak`

It does not remove directories.

## Safety Rules

- no image generation
- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no real board modification such as `api-test-board`
- no metadata sidecar modification
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-duplicate-item-repair-regression
```

Expected:

```text
Reference board duplicate item repair regression OK
```
