# Reference Board Store Backup CLI Implementation

## What Was Implemented

M34.41 adds `scripts/reference-board-store-backup.sh`, a safe CLI that backs up one reference board runtime JSON file.

The backup script copies only the selected board JSON bytes. It does not modify the source board file, copy source assets, copy metadata sidecars, repair data, create ZIP/PDF files, or trigger generation.

Backup should be run before `APPLY=1` repair-schema.

## Required BOARD_ID

`BOARD_ID` is required.

The board id must follow the safe board id policy:

- lowercase letters
- numbers
- dash
- underscore
- no slash
- no dot-dot
- no spaces
- not empty

## Env Vars

- `REFERENCE_BOARD_RUNTIME_DIR`, default `/home/cuneyt/MoE/runtime/reference-boards`
- `BOARD_ID`, required
- `BACKUP_DIR`, default `${REFERENCE_BOARD_RUNTIME_DIR}/backups`
- `REPORT_PATH`, default `/tmp/moe-reference-board-store-backup-report.json`

`BACKUP_DIR` must be the `backups` directory directly under the reference board runtime directory.

## Backup Filename

Backup filename format:

```text
reference-board-{BOARD_ID}-{YYYYMMDD-HHMMSS}.json.bak
```

The script never overwrites an existing backup file.

## Backup Directory

Default backup directory:

```text
/home/cuneyt/MoE/runtime/reference-boards/backups
```

The directory is created if missing. It stays under runtime, not the source repo.

## Report Schema

The script writes a local operator report:

```json
{
  "schema_version": "1.0",
  "report_type": "reference_board_store_backup",
  "created_at": "timestamp",
  "runtime_dir": "runtime reference board directory",
  "board_id": "board id",
  "source_file": "source board JSON",
  "backup_dir": "backup directory",
  "backup_file": "created backup file",
  "backup_created": true,
  "findings": [],
  "safety_flags": {
    "source_assets_modified": false,
    "board_file_modified": false,
    "backup_created": true,
    "repair_applied": false,
    "generation_triggered": false
  }
}
```

## Exit Codes

- `0`: backup created
- `1`: backup failed
- `2`: invalid usage, missing `BOARD_ID`, or invalid `BOARD_ID`
- `3`: source board missing

## Safety Rules

- no generated images
- no runtime export files
- no ZIP/PDF
- no source asset copy/move/delete
- no metadata sidecar copy
- no source board modification
- no repair
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution
- no generation

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
BOARD_ID=api-test-board make reference-board-store-backup
```

### Show report
```bash
jq . /tmp/moe-reference-board-store-backup-report.json
```

### List backups
```bash
ls -la /home/cuneyt/MoE/runtime/reference-boards/backups
```

## What Is Not Implemented Yet

- repair mode
- restore mode
- all-board backup
- backup manifest
- dashboard backup button
- backend backup endpoint
- source asset backup
- ZIP/PDF export
