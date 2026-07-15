# Reference Board Store Repair Regression

## What Was Implemented

M34.43 adds `scripts/reference-board-store-repair-regression.sh`, a controlled regression for the reference board store repair CLI.

The regression uses a temporary fixture board and verifies dry-run behavior, backup-required behavior, backup creation, guarded `APPLY=1` repair, validation after repair, and cleanup.

## Test Fixture Behavior

The script creates one temporary board:

```text
/home/cuneyt/MoE/runtime/reference-boards/repair-regression-board.json
```

The fixture is valid JSON but intentionally needs safe `repair-schema` changes:

- board `safety_label` missing
- title has leading/trailing whitespace
- description has leading/trailing whitespace
- one item `selected_reason` has leading/trailing whitespace
- one item has duplicate and empty tags
- one item has missing tags
- one item has missing `selected_reason`

The fixture uses fake output-card references and does not create source asset files.

## Dry-Run Checks

The regression runs:

```text
BOARD_ID=repair-regression-board scripts/reference-board-store-repair.sh
```

It verifies:

- the command does not crash
- report type is `reference_board_store_repair`
- `apply` is false
- `board_file_modified` is false
- proposed actions exist
- the board file still contains original untrimmed and duplicate data

## APPLY=1 Without Backup Check

The regression deletes matching fixture backups, then runs:

```text
BOARD_ID=repair-regression-board APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- the command exits non-zero
- `backup_required_missing` is reported
- the board file is not modified

## Backup Then APPLY=1 Check

The regression runs:

```text
BOARD_ID=repair-regression-board scripts/reference-board-store-backup.sh
BOARD_ID=repair-regression-board APPLY=1 scripts/reference-board-store-repair.sh
```

It verifies:

- a backup file is created
- repair succeeds
- `board_file_modified` is true
- `repair_applied` is true
- applied actions are present

## Validate After Repair

After repair, the regression runs:

```text
BOARD_ID=repair-regression-board scripts/reference-board-store-validate.sh
```

Expected:

- validation report type is `reference_board_store_validation`
- validation findings are empty

## Cleanup Behavior

The script removes only:

- `/home/cuneyt/MoE/runtime/reference-boards/repair-regression-board.json`
- `/home/cuneyt/MoE/runtime/reference-boards/backups/reference-board-repair-regression-board-*.json.bak`

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
make reference-board-store-repair-regression
```

Expected:

```text
Reference board store repair regression OK
```
