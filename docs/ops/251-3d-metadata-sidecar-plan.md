# 3D Metadata Sidecar Plan

## Purpose

Define the metadata sidecar schema for future generated 3D assets.

## Scope

- Plan sidecar schema.
- Plan validation rules.
- Plan relationship between config, generator, output files, and reports.
- Do not generate assets.
- Do not write runtime sidecars.
- Do not run Blender.

## Sidecar Location

Future sidecars should be written under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d/metadata
```

Future sidecar filename pattern:

```text
{asset_name}-{timestamp}.json
```

Do not create this folder or files in this milestone.

## Required Fields

- `schema_version`
- `asset_type`: `3d_model`
- `source`: `blender_parametric`
- `generator_script`
- `generator_version`
- `project_name`
- `asset_name`
- `asset_category`
- `config_path`
- `config_hash`
- `parameters`
- `units`
- `coordinate_system`
- `component_count`
- `component_types`
- `output_files`
- `created_at`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`
- `generation_mode`
- `operator_review_required`
- `notes`

## Output Files Shape

Plan:

```json
{
  "output_files": {
    "blend": "blender/file.blend",
    "glb": "glb/file.glb",
    "obj": null,
    "preview": null,
    "report": "reports/file.json"
  }
}
```

Rules:

- Paths should be runtime-relative where possible.
- No absolute host paths in exported/dashboard-facing metadata unless operator-local diagnostics explicitly require them.
- No source repo paths for generated outputs.
- No model backup paths.

## Safety Flags

Future real generation sidecars should include:

```json
{
  "safety_flags": {
    "visual_reference_only": true,
    "structural_certification": false,
    "runtime_assets_written": true,
    "source_assets_modified": false,
    "metadata_written": true,
    "generation_triggered": true,
    "operator_review_required": true
  }
}
```

These values are for future real generation sidecars. Dry-run plan JSON should continue to report `runtime_assets_written` false and `generation_triggered` false.

## Config Relationship

Sidecars should include:

- `config_path`
- `config_hash`
- `config_summary`
- parameters copied or summarized from config
- `component_count`
- component type counts

The sidecar should make an output traceable back to its source config without embedding unsafe paths or secrets.

## Generator Relationship

Sidecars should include:

- `generator_script`
- `generator_version`
- `git_commit` if available later
- `generation_mode`
- `created_at`
- `runtime_output_root`

## Validation Rules

Future sidecar validator should check:

- required fields exist
- `asset_type` is `3d_model`
- `source` is `blender_parametric`
- `safety_label` is `visual_reference_only`
- `structural_certification` is false
- output files are runtime-relative or under runtime root
- no repo paths in `output_files`
- no model backup paths
- `component_count` is non-negative
- `created_at` is present
- `config_hash` is present for config-based generation

## Privacy and Secret Safety

- no environment dump
- no API keys
- no full shell command history
- no home directory traversal leaks
- no arbitrary filesystem listing
- no model path leakage beyond approved operator-local diagnostics

## Dashboard Use Later

Future dashboard can read:

- `asset_name`
- `asset_category`
- output formats
- `created_at`
- `safety_label`
- dimensions/config summary
- `component_count`
- preview availability

Dashboard should not use sidecar metadata to trigger generation or shell commands.

## Example Sidecar Shape

Illustrative source-only example:

```json
{
  "schema_version": "1.0",
  "asset_type": "3d_model",
  "source": "blender_parametric",
  "generator_script": "apps/3d-generator/generic_parametric_blender.py",
  "generator_version": "planned",
  "project_name": "generic_3d_example",
  "asset_name": "simple_frame_example",
  "asset_category": "generic_structure",
  "config_path": "configs/3d/generic-object.example.json",
  "config_hash": "sha256:example",
  "parameters": {
    "dimensions": {
      "width_mm": 1200,
      "depth_mm": 600,
      "height_mm": 900
    }
  },
  "units": "mm",
  "coordinate_system": {
    "origin": "base_reference_point",
    "x_axis": "width_left_to_right",
    "y_axis": "depth_back_to_front",
    "z_axis": "height_base_to_up"
  },
  "component_count": 1,
  "component_types": {
    "rectangular_prism": 1
  },
  "output_files": {
    "blend": "blender/simple_frame_example-20260716T120000Z.blend",
    "glb": "glb/simple_frame_example-20260716T120000Z.glb",
    "obj": null,
    "preview": null,
    "report": "reports/simple_frame_example-20260716T120000Z.json"
  },
  "created_at": "2026-07-16T12:00:00Z",
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "generation_mode": "guarded",
  "operator_review_required": true,
  "safety_flags": {
    "visual_reference_only": true,
    "structural_certification": false,
    "runtime_assets_written": true,
    "source_assets_modified": false,
    "metadata_written": true,
    "generation_triggered": true,
    "operator_review_required": true
  },
  "notes": "Example only. Not a runtime sidecar."
}
```

## Non-Goals

- no sidecar writer implementation
- no sidecar validator implementation
- no real generation
- no runtime files
- no dashboard integration
- no ZIP/PDF
- no source asset mutation

## Future Milestones

- M35.9 3D Output Cards Plan
- M35.10 Guarded Blender Generation Implementation
- M35.11 3D Metadata Sidecar Writer
- M35.12 3D Metadata Sidecar Validator
- M35.13 First Local Blender Generation Drill
