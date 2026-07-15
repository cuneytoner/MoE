# Reference Board Store Repair CLI Plan

## Purpose

This document plans a future CLI for validating and repairing reference board runtime JSON files.

M34.39 defines the interface and safety contract only. It does not implement a repair script, backup script, backend endpoint, dashboard button, runtime export file, ZIP/PDF artifact, or source asset mutation.

M34.40 implements the first read-only validate CLI slice.

M34.41 implements backup mode as a separate safe CLI before repair modes.

M34.42 implements the first repair-schema CLI slice.

M34.43 covers repair-schema with regression fixture.

## Proposed Script

Future script:

```text
scripts/reference-board-store-repair.sh
```

Do not implement it in this milestone.

## CLI Principles

- dry-run default
- explicit `APPLY=1` required for any write
- backup required before repair
- no source asset mutation
- no generation
- no dashboard shell execution
- no arbitrary filesystem traversal
- one board at a time by default
- all-board mode only with explicit flag later
- report every proposed action

## Environment Variables

Planned environment variables:

- `REFERENCE_BOARD_RUNTIME_DIR`
- `BOARD_ID`
- `MODE`
- `APPLY`
- `BACKUP`
- `REPORT_PATH`

Planned defaults:

- `MODE=validate`
- `APPLY=0`
- `BACKUP=1` for repair modes
- `REPORT_PATH` under `/tmp` or runtime reports, to be decided by the implementation milestone

## Modes

Planned modes:

- `validate`
- `backup`
- `repair-schema`
- `remove-duplicate-items`
- `mark-stale-items`
- `validate-and-report`

Do not implement these modes in M34.39.

## Validate Mode

Validate mode should check:

- board file exists
- JSON parses
- required board fields exist
- `items` is a list
- item ids are unique
- card ids are present
- `asset_type` is known
- `relative_runtime_path` is relative
- no absolute host paths in board fields
- `selected_reason` within limit
- tags within limits

## Backup Mode

Backup mode should use the M34.38 policy:

```text
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.json.bak
```

No source asset backup is included.

## Repair Schema Mode

Safe schema repairs may include:

- add missing safe defaults only if unambiguous
- normalize tags
- trim strings
- preserve unknown safe fields
- never invent missing source assets
- never invent missing metadata

## Duplicate Item Repair

Duplicate item repair should:

- detect duplicate `card_id` or `item_id`
- preserve first occurrence
- report removed duplicates
- apply only with `APPLY=1`

## Stale Item Handling

Stale item handling should:

- detect missing output card
- mark stale, do not delete by default
- never recreate asset
- let export still show the item with metadata unavailable or stale status

## Atomic Write Plan

- write to temporary file in same directory
- fsync if feasible later
- rename into place
- avoid partial writes
- never overwrite backup

## Report Format

Plan JSON report fields:

- `schema_version`
- `report_type`
- `board_id`
- `mode`
- `apply`
- `backup_created`
- `findings`
- `proposed_actions`
- `applied_actions`
- `skipped_actions`
- `safety_flags`
- `created_at`

## Exit Codes

- `0` success/no findings
- `1` validation findings
- `2` invalid CLI usage
- `3` store unavailable
- `4` backup failed
- `5` repair failed

## Operator Playbook

1. Run export regression.
2. Run malformed store regression.
3. Run the future repair CLI in validate mode.
4. Inspect report.
5. Run backup mode.
6. Run repair mode with `APPLY=1` only after review.
7. Rerun regressions.

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-export-regression
```

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-malformed-store-regression
```

## Non-Goals

- no script implementation in this milestone
- no dashboard repair button
- no backend repair endpoint
- no source asset copy/move/delete
- no generation
- no ZIP/PDF
- no shell execution through dashboard/API

## Future Milestones

- M34.40 Reference Board Store Validate CLI Implementation
- M34.41 Reference Board Store Backup CLI Implementation
- M34.42 Reference Board Store Repair CLI Implementation
- M34.43 Reference Board Store Repair Regression
