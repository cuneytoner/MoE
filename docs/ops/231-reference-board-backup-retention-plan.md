# Reference Board Backup Retention Plan

## Purpose

Plan how reference board backup files should be reviewed, retained, and eventually cleaned up safely.

## Current Backup Behavior

- Backup CLI creates one board JSON backup at a time.
- Backups are stored under runtime:

```text
/home/cuneyt/MoE/runtime/reference-boards/backups
```

- Backup files use:

```text
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.json.bak
```

- Backup CLI does not delete old backups.
- Repair CLI requires backup before `APPLY=1`.
- Source assets are not backed up by this workflow.
- Metadata sidecars are not backed up by this workflow.

## Retention Goals

- prevent unbounded backup growth
- preserve recent repair safety points
- preserve enough history for manual rollback investigation
- avoid automatic deletion without review
- keep runtime/source/model separation
- avoid touching generated media or model files

## Proposed Retention Policy

Plan values, not implementation:

- keep at least latest 10 backups per board
- keep backups from last 30 days per board
- keep any backup referenced by a review report if such references exist later
- never delete backups for unknown/malformed board ids automatically
- never delete backups unless dry-run report is reviewed

## Future Cleanup CLI Plan

Plan a future script:

```text
scripts/reference-board-backup-retention.sh
```

Modes:

- `report`
- `dry-run-cleanup`
- `apply-cleanup`

Defaults:

- `MODE=report`
- `APPLY=0`
- `BOARD_ID` optional
- if `BOARD_ID` is omitted, report all boards only
- deletion requires `APPLY=1` and explicit `MODE=apply-cleanup`

## Cleanup Safety Rules

- dry-run first
- `APPLY=1` required for deletion
- no recursive deletes
- only delete files matching strict backup filename pattern
- only delete files under `reference-boards/backups`
- never delete board JSON files
- never delete source assets
- never delete metadata sidecars
- never delete generated images/SVGs
- never delete model files
- never follow symlinks
- report every proposed deletion
- preserve latest backup per board even if older than retention window

## Report Format Plan

Plan JSON fields:

- `schema_version`
- `report_type`
- `created_at`
- `backup_dir`
- `mode`
- `apply`
- `board_id`
- `scanned_count`
- `retained_count`
- `proposed_delete_count`
- `applied_delete_count`
- `backups_by_board`
- `proposed_deletions`
- `applied_deletions`
- `skipped_deletions`
- `safety_flags`

Safety flags:

- `board_files_modified`: false
- `source_assets_modified`: false
- `metadata_modified`: false
- `model_files_modified`: false
- `generation_triggered`: false

## Restore Relationship

Retention should not remove backups needed for operator-reviewed restore.

Restore workflow is separate and not implemented here. Future restore docs should define how to select a backup safely.

## Operator Playbook

- list backups
- run retention report
- inspect proposed deletions
- confirm board id and backup age
- run `APPLY=1` only after review
- rerun report
- run git safety check

## Stop Conditions

Do not clean up if:

- `backup_dir` is unexpected
- filename does not match strict pattern
- `board_id` looks unsafe
- report proposes deleting latest backup for a board
- report touches source assets, metadata, generated media, or models
- operator does not understand proposed deletions

## Non-Goals

- no cleanup implementation now
- no backup deletion now
- no restore implementation
- no source asset backup
- no metadata sidecar backup
- no generated media cleanup
- no model cleanup
- no ZIP/PDF
- no generation
- no dashboard cleanup button
- no backend cleanup endpoint

## Future Milestones

- M34.54 Reference Board Export Review UI Polish
- M34.55 Reference Board Backup Retention CLI Plan
- M34.56 Reference Board Backup Retention CLI Implementation
- M34.57 Reference Board Restore Plan
