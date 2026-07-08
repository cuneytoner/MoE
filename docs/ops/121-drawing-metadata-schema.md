# Drawing Metadata Schema

This document defines the proposed sidecar JSON schema for deterministic drawing outputs.

M34.7 implements the first drawing sidecar metadata generation for pergola drawings and generic drawing demo.

## JSON Example

```json
{
  "schema_version": "1.0",
  "asset_type": "drawing_svg",
  "asset_name": "side_elevation.svg",
  "asset_path": "/home/cuneyt/MoE/runtime/pergola/drawings/side_elevation.svg",
  "relative_runtime_path": "pergola/drawings/side_elevation.svg",
  "created_at": "2026-07-07T18:17:00Z",
  "source": "deterministic-svg",
  "script": "tools/pergola-drawings/generate_pergola_svg.py",
  "project": "pergola-case-study",
  "drawing_kind": "side_elevation",
  "units": "mm",
  "geometry": {
    "wall_width_mm": 5100,
    "depth_mm": 1900,
    "roof_overhang_mm": 300,
    "post_mm": 100,
    "beam_width_mm": 50,
    "beam_height_mm": 100
  },
  "safety_label": "draft_drawing",
  "notes": "Draft deterministic SVG. Verify dimensions before build."
}
```

## Required Fields

- `schema_version`
- `asset_type`
- `asset_name`
- `asset_path`
- `relative_runtime_path`
- `created_at`
- `source`
- `script`
- `drawing_kind`
- `units`
- `safety_label`

## Optional Fields

- `project`
- `geometry`
- `notes`
- `tags`
- `operator`
- `review_status`
- `reference_board_status`
- `source_config`
- `sheet_number`

## Safety Notes

- Store metadata as sidecar JSON in runtime.
- Use `draft_drawing` until dimensions and assumptions are reviewed.
- Geometry values should record source assumptions, not hide them.
- Do not use metadata as proof of engineering approval.
- Do not store secrets, API keys, or arbitrary shell history.
