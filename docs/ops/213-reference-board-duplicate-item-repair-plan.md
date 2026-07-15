# Reference Board Duplicate Item Repair Plan

## Purpose

This document plans safe detection and future repair of duplicate reference board items.

M34.44 is documentation only. It does not implement duplicate deletion, repair script changes, Gateway behavior, dashboard behavior, runtime file mutation, source asset mutation, ZIP/PDF behavior, or generation.

## Current Behavior

- Validate CLI detects duplicate `item_id` and duplicate `card_id` if implemented.
- Repair CLI currently does not remove duplicate items.
- Repair CLI only supports conservative `repair-schema` behavior.
- Board files are runtime JSON files.
- Source assets are never modified.

## Duplicate Types

- duplicate `item_id`
- duplicate `card_id`
- duplicate `relative_runtime_path`
- near-duplicate items with different ids but same card reference
- accidental repeated add from dashboard/API

## Detection Rules

Future detection should be deterministic:

- exact duplicate `item_id`
- exact duplicate `card_id`
- exact duplicate `relative_runtime_path` when present
- preserve original item order for review
- report all duplicates before any repair

## Safety Principles

- dry-run first
- `APPLY=1` required for any future removal
- backup required before apply
- never delete source assets
- never delete metadata sidecars
- never delete output cards
- never invent replacement items
- never merge notes automatically unless explicitly planned later
- preserve first occurrence by default
- report removed/skipped items

## Future Repair Strategy

Plan a future mode:

```text
MODE=remove-duplicate-items
```

Default behavior:

- preserve first occurrence
- skip duplicate entries
- write only board JSON if `APPLY=1`
- keep removed duplicate details in report
- do not delete assets
- do not rewrite if no duplicates exist

## Conflict Cases

These cases require human review:

- duplicate `item_id` with different `card_id`
- duplicate `card_id` with different `selected_reason`
- duplicate `card_id` with different tags
- duplicate `relative_runtime_path` with different `asset_type`
- malformed items
- missing required fields

## Report Format Additions

Future duplicate repair reports should add:

- `duplicate_groups`
- `preserved_item_id`
- `duplicate_item_ids`
- `conflict_reason`
- `proposed_removals`
- `applied_removals`
- `skipped_removals`

## Operator Playbook

1. Run validate.
2. Inspect duplicate findings.
3. Run backup.
4. Run future duplicate repair dry-run.
5. Inspect report.
6. Run `APPLY=1` only after review.
7. Rerun validate and export regression.

## Non-Goals

- no implementation in this milestone
- no duplicate deletion now
- no source asset deletion
- no metadata deletion
- no dashboard repair button
- no backend repair endpoint
- no ZIP/PDF
- no generation
- no shell execution through dashboard/API

## Future Milestones

- M34.45 Reference Board Stale Item Handling Plan
- M34.46 Reference Board Duplicate Item Repair Implementation
- M34.47 Reference Board Duplicate Item Repair Regression
