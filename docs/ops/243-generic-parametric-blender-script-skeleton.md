# Generic Parametric Blender Script Skeleton

## What Was Added

M35.4 adds a source-only dry-run skeleton for the future generic parametric Blender pipeline:

- `apps/3d-generator/README.md`
- `apps/3d-generator/generic_parametric_blender.py`
- `scripts/test-3d-generator-skeleton.sh`
- `make test-3d-generator-skeleton`

M35.5 adds a source-only generic parameter config draft and config validation.

M35.6 adds a first dry-run review script for the skeleton.

## No `bpy` Import At Module Import

The script must run with normal Python, so it does not import `bpy` at module import time. Future Blender-specific imports must remain inside explicitly guarded execution paths.

## CLI Modes

```bash
python apps/3d-generator/generic_parametric_blender.py --help
python apps/3d-generator/generic_parametric_blender.py --dry-run
python apps/3d-generator/generic_parametric_blender.py --plan-json
```

No arguments default to dry-run behavior.

## Dry-Run Behavior

Dry-run prints a human-readable plan. It does not run Blender, trigger generation, write runtime assets, or modify source assets.

## Plan JSON Behavior

`--plan-json` prints JSON only. The plan includes the runtime output root, primitive placeholders, metadata plan, and safety flags.

## Output Root Validation

`--output-root` is optional. If provided, it must resolve under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

The script rejects path traversal, relative paths, and paths outside the approved runtime output root.

## Safety Flags

The JSON plan includes:

- `dry_run`
- `real_generation_requested`
- `real_generation_enabled`
- `blender_execution_attempted`: `false`
- `runtime_assets_written`: `false`
- `source_assets_modified`: `false`
- `generation_triggered`: `false`

## Metadata Plan

The metadata plan includes:

- `schema_version`
- `asset_type`: `3d_model`
- `source`: `blender_parametric`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`

## Primitive Placeholders

The skeleton lists future primitive builders:

- `rectangular_prism`
- `cylinder`
- `plane`
- `sloped_plane`
- `frame`
- `panel`
- `connector_placeholder`
- `guide_line`
- `label_anchor`

## No Generated Assets

M35.4 does not create `.blend`, `.glb`, `.obj`, `.fbx`, `.mtl`, preview images, renders, or runtime 3D assets.

## How To Test

```bash
make check-layout
make check-python-syntax
bash -n scripts/test-3d-generator-skeleton.sh
make test-3d-generator-skeleton
```
