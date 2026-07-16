# Generic 3D Parameter Config Draft

## What Was Added

M35.5 adds a source-only generic 3D parameter config draft and validation path for the dry-run Blender skeleton.

M35.6 reviews config loading through the dry-run review script.
M35.7 uses the generic config as the planned input for a future guarded generation drill.

## Config File Path

```text
configs/3d/generic-object.example.json
```

The file is text-only JSON. It does not reference external textures, runtime output files, or binary assets.

## Generic Schema Fields

- `schema_version`
- `project_name`
- `asset_name`
- `asset_category`
- `units`
- `safety_label`
- `structural_certification`
- `coordinate_system`
- `dimensions`
- `components`
- `materials`
- `output_plan`
- `metadata`

## Supported Component Types

- `rectangular_prism`
- `cylinder`
- `plane`
- `sloped_plane`
- `frame`
- `panel`
- `connector_placeholder`
- `guide_line`
- `label_anchor`

## Safety Fields

The config must keep:

- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`
- `output_plan.runtime_output_root`: `/home/cuneyt/MoE/runtime/media/outputs/3d`

## Validation Rules

The dry-run skeleton rejects:

- non-json config files
- missing config files
- malformed JSON
- config paths outside `configs/3d`
- missing `schema_version`
- `safety_label` values other than `visual_reference_only`
- `structural_certification` values other than `false`
- missing or empty components
- duplicate `component_id` values
- unsupported `component_type` values
- non-positive dimensions
- runtime output roots outside `/home/cuneyt/MoE/runtime/media/outputs/3d`
- path traversal in config paths

## CLI Usage With `--config`

```bash
python3 apps/3d-generator/generic_parametric_blender.py --config configs/3d/generic-object.example.json --dry-run
python3 apps/3d-generator/generic_parametric_blender.py --config configs/3d/generic-object.example.json --plan-json
```

`--plan-json` includes `config_loaded` and `config_summary` when a config is supplied.

## No Generated Assets

The config validation path does not run Blender, import `bpy`, generate assets, write runtime files, or modify source assets.

## How To Test

```bash
make check-layout
make check-python-syntax
bash -n scripts/test-3d-parameter-config.sh
make test-3d-parameter-config
```
