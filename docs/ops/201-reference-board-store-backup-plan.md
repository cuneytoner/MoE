# Reference Board Store Backup Plan

## Purpose

Backups protect reference board JSON files before validation or repair operations.

M34.38 defines the backup strategy before any backup or repair CLI is implemented. It does not create runtime backup files, copy source assets, add dashboard buttons, or add backend endpoints.

M34.39 references this backup policy as a prerequisite for repair CLI modes.

Validation runs before any future backup or repair action.

## Current Store Model

- Reference boards are runtime JSON files.
- Board files contain references to output cards.
- Source assets remain in original runtime locations.
- Backups must not copy source assets.
- Backups must not trigger generation.

Reference board backup protects review metadata only. Generated images, deterministic drawings, metadata sidecars, model files, and exported review artifacts remain outside this backup scope.

## Backup Scope

The first backup workflow should support:

- one board file backup
- optional all-board backup later
- metadata sidecars are not backed up in this phase
- source assets are not backed up in this phase
- model files are never backed up by this workflow

All-board backup should be a future extension with separate safety review.

## Backup Location

Future backups should live under the runtime reference board area, conceptually:

```text
runtime/reference-boards/backups/
```

For PC-1, the runtime root is normally:

```text
/home/cuneyt/MoE/runtime
```

Backup paths must stay outside the source repo.

## Backup Filename Policy

Use a safe deterministic filename format:

```text
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.json.bak
```

Rules:

- sanitized `board_id` only
- UTC timestamp
- no spaces
- no slash
- no dot-dot
- no user-controlled extension
- preserve original board JSON bytes if possible

The backup command should never overwrite an existing backup.

## Backup Manifest

A future backup command may emit an optional manifest:

```text
reference-board-backup-{YYYYMMDD-HHMMSS}.json
```

Manifest fields:

- `schema_version`
- `backup_type`
- `board_id`
- `source_filename`
- `backup_filename`
- `created_at`
- safety flags
- checksum if implemented later

## Backup Principles

- dry-run first
- backup before repair
- never overwrite an existing backup
- atomic write when possible
- report what was backed up
- cleanup policy must be explicit later
- no automatic deletion

## Restore Principles

- restore should be a separate explicit future milestone
- restore must require operator confirmation
- restore must not touch source assets
- restore must validate board JSON after restore

Restore is higher risk than backup and should not be bundled into the first backup implementation.

## Non-Goals

- no backup script in this milestone
- no repair script
- no dashboard backup button
- no source asset backup
- no metadata sidecar backup
- no ZIP/PDF
- no external upload
- no shell execution through dashboard/API

## Future Milestones

- M34.39 Reference Board Store Repair CLI Plan
- M34.40 Reference Board Store Validate CLI Implementation
- M34.41 Reference Board Store Backup CLI Implementation
- M34.42 Reference Board Store Repair CLI Implementation
