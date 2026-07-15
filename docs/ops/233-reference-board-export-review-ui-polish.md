# Reference Board Export Review UI Polish

## What Was Changed

M34.54 polishes the Dashboard reference board export review panel so stale and duplicate review status is easier to see.

The change is UI-only and read-only. It does not add repair, backup, apply, generation, delete, move, or source asset actions.

## JSON Export Review Summary

When a JSON export is loaded, the Dashboard safely parses the response and shows a compact summary above the raw JSON panel:

- total items
- needs review count
- stale count
- duplicate hint count

If parsing fails, the raw JSON panel remains available.

## Per-Item Review Status Rows

For parsed JSON exports, the Dashboard shows compact per-item rows with:

- item name or item id
- needs review yes/no/unknown
- stale yes/no/unknown
- stale reason when present
- duplicate hint yes/no/unknown

Missing `review_status` is treated as unknown, not an error.

## Markdown Review Status Note

When a Markdown export includes `Review status`, the Dashboard shows:

```text
Markdown includes review status sections.
```

Markdown text is not parsed into structured item rows.

## Read-Only Safety Boundaries

- no runtime board mutation
- no source asset copy/move/delete
- no metadata sidecar mutation
- no backup action
- no repair action
- no `APPLY=1` control
- no generation
- no arbitrary filesystem browsing
- no Gateway/dashboard shell execution

## No Repair/Apply Controls

The UI remains a review surface only. Operators must use the documented CLI flow for validate, backup, dry-run, and apply.

## How To Test

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
make test-dashboard-ui
make reference-board-export-regression
```

Open the Dashboard media section and use the Reference Boards export buttons:

```text
http://127.0.0.1:8500/#media
```

Expected:

- JSON export summary is visible.
- Per-item status rows are visible for JSON export.
- Raw JSON remains visible.
- Markdown export shows the review status note when applicable.
- Download JSON and Download Markdown behavior is unchanged.
- No repair, backup, `APPLY=1`, delete source asset, or generation controls are added.
