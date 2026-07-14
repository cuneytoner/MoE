# Reference Board Store Repair Plan

## Purpose

This document plans safe repair workflows for reference board runtime store issues.

M34.37 is planning only. It does not implement repair commands, backend endpoints, dashboard buttons, export files, ZIP/PDF artifacts, or source asset mutation.

M34.38 defines backup behavior that must precede repair tooling.

## Current Store Model

- Reference boards are runtime JSON files.
- Board items are references to output cards.
- Source assets remain in their original runtime locations.
- Metadata sidecars remain associated with their source output artifacts.
- Repair must never modify source assets.
- Repair must never trigger generation.

The reference board store is review metadata. It is not the owner of generated images, deterministic drawings, model files, or metadata sidecar source assets.

## Failure Types

Repair planning should cover:

- malformed board JSON
- missing board file
- duplicate board id
- duplicate item references
- stale item references
- missing output card
- missing metadata sidecar
- invalid metadata sidecar
- invalid board schema
- invalid item schema
- unsafe field values
- partial write / truncated JSON
- permission errors

## Repair Principles

- inspect first, modify later
- backup before repair
- no automatic deletion by default
- no source asset mutation
- no model file access
- no shell execution through dashboard/API
- operator-confirmed repair only
- dry-run first
- write repaired board atomically
- preserve unknown safe fields where possible
- emit summary report

## Proposed Repair Tool

A future milestone may add:

```text
scripts/reference-board-store-repair.sh
```

Planned modes:

- `dry-run`
- `backup`
- `repair-schema`
- `remove-duplicate-items`
- `mark-stale-items`
- `validate-only`

Do not implement this script in M34.37.

## Backup Plan

Before repair, a future tool should back up one board file.

Suggested backup filename format:

```text
{board_id}.{YYYYMMDD-HHMMSS}.json
```

Suggested backup location:

```text
/home/cuneyt/MoE/runtime/reference-boards/backups
```

This phase should not back up source assets. Source generated images, drawings, metadata sidecars, model files, and archives remain outside repair scope.

## Repair Report

A future repair operation should emit a JSON or Markdown report with:

- board id
- checked file
- findings
- actions proposed
- actions applied
- backup path if created
- safety flags
- timestamp

The report should be operator-readable and safe to paste into notes. It should not expose secrets, model paths, or unnecessary host paths.

## Non-Repairable Cases

- unknown corrupted content with no parseable `board_id`
- missing source output card cannot be recreated
- missing generated source asset cannot be recreated
- malformed metadata should be marked unavailable, not invented
- source asset deletion is not repaired by reference board store repair

If source assets are missing, the repair tool can only record that the reference is stale or unavailable.

## Operator Playbook

1. Run normal export regression.
2. Run malformed store regression.
3. Inspect reference boards through safe read-only views.
4. Run the future repair script in `dry-run`.
5. Review the report.
6. Create a backup.
7. Apply operator-confirmed repair.
8. Rerun regressions.

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

## Explicit Non-Goals

- no automatic repair in this milestone
- no dashboard repair button
- no delete button
- no source asset copy/move/delete
- no generation
- no ZIP/PDF
- no shell execution

## Proposed Future Milestones

- M34.39 Reference Board Store Repair CLI Plan
- M34.40 Reference Board Store Validate CLI Implementation
- M34.41 Reference Board Store Backup CLI Implementation
- M34.42 Reference Board Store Repair CLI Implementation
