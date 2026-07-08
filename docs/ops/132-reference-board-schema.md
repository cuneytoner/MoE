# Reference Board Schema

This document defines the proposed reference board JSON schema.

## Example

```json
{
  "schema_version": "1.0",
  "board_id": "pergola-visual-reference-board-20260708",
  "title": "Pergola Visual Reference Board",
  "description": "Selected visual references and draft drawings for pergola case study.",
  "created_at": "2026-07-08T08:00:00Z",
  "updated_at": "2026-07-08T08:00:00Z",
  "safety_label": "visual_reference_only",
  "items": [
    {
      "card_id": "image:moe_pergola_project_20260707_131301_00001_.png",
      "asset_type": "image",
      "name": "moe_pergola_project_20260707_131301_00001_.png",
      "relative_runtime_path": "media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png",
      "metadata_path": null,
      "selected_reason": "Closest visual reference for covered pergola concept.",
      "tags": ["pergola", "visual-reference", "concept"],
      "safety_label": "visual_reference_only"
    },
    {
      "card_id": "drawing_svg:side_elevation.svg",
      "asset_type": "drawing_svg",
      "name": "side_elevation.svg",
      "relative_runtime_path": "pergola/drawings/side_elevation.svg",
      "metadata_path": "/home/cuneyt/MoE/runtime/pergola/drawings/side_elevation.json",
      "selected_reason": "Draft deterministic side elevation.",
      "tags": ["pergola", "draft-drawing", "svg"],
      "safety_label": "draft_drawing"
    }
  ]
}
```

## Required Board Fields

- `schema_version`
- `board_id`
- `title`
- `created_at`
- `updated_at`
- `safety_label`
- `items`

## Optional Board Fields

- `description`
- `project`
- `tags`
- `review_status`
- `notes`

## Required Item Fields

- `card_id`
- `asset_type`
- `name`
- `relative_runtime_path`
- `selected_reason`
- `tags`
- `safety_label`

## Optional Item Fields

- `metadata_path`
- `notes`
- `rank`
- `review_status`

## Safety Notes

Boards should use `relative_runtime_path` values from output cards. They should not accept arbitrary absolute asset paths.
