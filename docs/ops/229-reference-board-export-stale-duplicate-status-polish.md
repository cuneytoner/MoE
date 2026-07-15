# Reference Board Export Stale Duplicate Status Polish

## What Was Changed

M34.52 adds review status fields to reference board JSON exports and a compact Review status section to Markdown exports.

The change is export-only. It does not mutate runtime board JSON, repair boards, delete duplicates, mark stale items, inspect source assets beyond existing export behavior, or create runtime export files.

## JSON review_status Object

Each exported item now includes:

```json
{
  "review_status": {
    "stale": false,
    "stale_reason": null,
    "stale_checked_at": null,
    "duplicate_hint": false,
    "duplicate_keys": [],
    "needs_review": false
  }
}
```

`needs_review` is `true` when the item is stale or has a duplicate hint.

## Markdown Review status Section

Each Markdown item includes:

```text
### Review status

- Needs review: no
```

When an item needs review, the section can include stale and duplicate details:

```text
- Needs review: yes
- Stale: yes
- Stale reason: metadata_path_unsafe
- Duplicate hint: no
```

## Duplicate Hint Behavior

Duplicate hints are computed within the exported board response.

The export checks for duplicate:

- `item_id`
- `card_id`
- `relative_runtime_path` when present

Duplicate keys use safe review strings such as:

```text
item_id:example_item
card_id:image:media/outputs/images/example.png
relative_runtime_path:media/outputs/images/example.png
```

The export does not remove or merge duplicate items.

## Stale Marker Display Behavior

If a board item already has stale markers, the export surfaces:

- `stale`
- `stale_reason`
- `stale_checked_at`

The export does not add stale markers. Use `MODE=mark-stale-items` only through the guarded repair CLI flow.

## Backward Compatibility

The JSON export keeps existing fields and adds `review_status` per item.

Markdown exports keep the board, safety, item, and metadata sections while adding Review status.

Download endpoints reuse the same export helpers, so downloaded JSON and Markdown include the same review status information.

M34.54 surfaces the export review status in the Dashboard UI.

## Safety Boundaries

- no runtime board mutation
- no source asset copy/move/delete
- no metadata sidecar modification
- no output card deletion
- no stale deletion
- no duplicate repair
- no generation
- no ZIP/PDF
- no dashboard repair controls
- no backend repair endpoint
- no arbitrary filesystem browsing

## How To Test

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
bash -n scripts/reference-board-export-regression.sh
make reference-board-export-regression
```

Optional full regression sequence:

```bash
make reference-board-malformed-store-regression
make reference-board-store-validate
make reference-board-store-repair-regression
make reference-board-duplicate-item-repair-regression
make reference-board-stale-item-regression
```
