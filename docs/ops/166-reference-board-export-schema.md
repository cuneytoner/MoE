# Reference Board Export Schema

## Planned JSON Shape

Reference board JSON export should use this planned shape:

```json
{
  "schema_version": "1.0",
  "export_type": "reference_board_review_pack",
  "exported_at": "...",
  "board": {
    "board_id": "...",
    "title": "...",
    "description": "...",
    "created_at": "...",
    "updated_at": "...",
    "safety_label": "visual_reference_only",
    "item_count": 1
  },
  "items": [
    {
      "item_id": "...",
      "card_id": "...",
      "asset_type": "image",
      "name": "...",
      "relative_runtime_path": "...",
      "selected_reason": "...",
      "tags": [],
      "safety_label": "...",
      "added_at": "...",
      "metadata_summary": {
        "source": "...",
        "script": "...",
        "workflow": "...",
        "model_name": "...",
        "prompt": "...",
        "seed": "...",
        "width": 512,
        "height": 512,
        "steps": 4,
        "drawing_kind": null,
        "geometry": null
      }
    }
  ],
  "safety": {
    "review_only": true,
    "source_assets_copied": false,
    "source_assets_deleted": false,
    "generation_triggered": false
  }
}
```

## Board Fields

- `board_id`
- `title`
- `description`
- `created_at`
- `updated_at`
- `safety_label`
- `item_count`

## Item Fields

- `item_id`
- `card_id`
- `asset_type`
- `name`
- `relative_runtime_path`
- `selected_reason`
- `tags`
- `safety_label`
- `added_at`
- `metadata_summary`

## Metadata Summary

Metadata summary should include stable review fields when available:

- source
- script
- workflow
- model_name
- prompt
- seed
- width
- height
- steps
- drawing_kind
- geometry

If metadata is missing or a field is not relevant, use `null` or omit non-required summary details according to the final implementation contract.

## Markdown Export Plan

Markdown export should include:

- title
- board metadata
- item table
- selected_reason
- tags
- relative_runtime_path
- metadata summary
- safety note

Markdown should remain a review artifact. It should not embed SVG directly until a dedicated SVG policy exists.

## Safety Flags

The export should include explicit safety flags:

- `review_only=true`
- `source_assets_copied=false`
- `source_assets_deleted=false`
- `generation_triggered=false`
