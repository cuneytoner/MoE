# Reference Board Duplicate Item Repair Implementation

## What Was Implemented

M34.46 extends `scripts/reference-board-store-repair.sh` with a second mode:

```text
MODE=remove-duplicate-items
```

The mode removes only later duplicate board item entries from the board JSON when `APPLY=1` and an existing backup is present.

M34.47 adds dedicated regression coverage for `MODE=remove-duplicate-items`.

M34.48 adds stale item marking as a separate repair mode. Duplicate repair remains separate from stale item marking.

## Supported Mode

Supported duplicate repair mode:

```text
MODE=remove-duplicate-items
```

Existing `MODE=repair-schema` remains available.

## Duplicate Detection Rules

The repair CLI detects duplicate groups by:

- duplicate `item_id`
- duplicate `card_id`
- duplicate `relative_runtime_path` when present

Detection preserves original item order and reports all duplicate groups before any write.

## Preserve-First Policy

For each duplicate key, the first occurrence in board item order is preserved. Later duplicate entries are proposed for removal.

The CLI does not merge notes, tags, selected reasons, names, asset types, paths, metadata, or source assets.

## Conflict Behavior

If duplicate items differ in `selected_reason`, `tags`, `name`, `asset_type`, or `relative_runtime_path`, the CLI reports `conflict_reason`.

The default action remains preserve-first and remove later duplicate board entries only when `APPLY=1`.

## Dry-Run Behavior

Dry-run is the default:

```text
APPLY=0
```

Dry-run reports:

- `duplicate_groups`
- `proposed_removals`
- `skipped_removals`
- `proposed_actions`
- `skipped_actions`

It does not modify the board file.

## APPLY=1 Behavior

With `APPLY=1`, the CLI:

- requires an existing backup when `REQUIRE_BACKUP=1`
- removes only later duplicate board item entries
- writes only the board JSON file
- updates `updated_at` when the board changes
- writes atomically through a temporary file and rename
- does not rewrite if no duplicates exist

## Backup Requirement

Before applying duplicate repair, run:

```bash
BOARD_ID=api-test-board make reference-board-store-backup
```

The repair CLI requires a matching backup:

```text
reference-board-{BOARD_ID}-*.json.bak
```

## Report Fields

Duplicate mode reports:

- `duplicate_groups`
- `preserved_item_id`
- `duplicate_item_ids`
- `duplicate_key_type`
- `duplicate_key`
- `conflict_reason`
- `proposed_removals`
- `applied_removals`
- `skipped_removals`
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
- no stale item behavior in duplicate repair mode
- no Gateway/dashboard repair button
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
```

### Dry-run duplicate repair
```bash
BOARD_ID=api-test-board MODE=remove-duplicate-items make reference-board-store-repair
jq . /tmp/moe-reference-board-store-repair-report.json
```

### Apply only after backup and review
```bash
BOARD_ID=api-test-board make reference-board-store-backup
BOARD_ID=api-test-board MODE=remove-duplicate-items APPLY=1 make reference-board-store-repair
```

## What Is Not Implemented Yet

- stale item removal
- source asset repair
- metadata sidecar repair
- dashboard repair button
- backend repair endpoint
