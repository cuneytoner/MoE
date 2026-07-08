# Dashboard Metadata Detail Drawer

## What Was Added

M34.15 adds a read-only metadata detail view to dashboard output cards.

Cards with `metadata_available=true` show a `View metadata` control.

M34.12 adds reference-board selection controls beside metadata viewing. Metadata remains read-only and is not used as an executable action source.

## UI Behavior

When selected, the dashboard fetches metadata through:

```text
GET /gateway/media/output-card-metadata/{card_id}
```

Metadata is displayed as text in a modal-style detail view.

## Supported Image Fields

- prompt
- seed
- width
- height
- steps
- workflow
- model_name
- model_family
- script
- safety_label
- relative_runtime_path
- notes

## Supported Drawing Fields

- project
- drawing_kind
- units
- geometry
- geometry_summary
- script
- safety_label
- relative_runtime_path
- notes

## Error States

If metadata cannot be fetched, the dashboard shows a warning and keeps the card usable.

Unknown metadata fields remain visible in a raw JSON fallback block.

## Safety Constraints

- Display metadata as inert text only.
- Do not execute metadata content.
- Do not use metadata paths as fetch links.
- Do not add edit controls.
- Do not add rerun or generate buttons.
- Do not add delete, move, or rename buttons.
- Do not expose arbitrary filesystem browsing.
- Do not build reference-board item requests from metadata paths.

## Browser Inspection Steps

1. Open `http://127.0.0.1:8500`.
2. Find `Media Output Cards`.
3. Find a card with `metadata`.
4. Click `View metadata`.
5. Confirm expected image or drawing fields are visible.
6. Confirm no edit, rerun, generate, delete, move, or rename controls are present.

## What Is Not Implemented Yet

- No metadata editing.
- No rerun from metadata.
- No metadata search.
- No metadata diff view.
- No metadata editing from reference-board selection.
