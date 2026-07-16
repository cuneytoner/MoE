# First Dry-Run Blender Script Review

## What Was Reviewed

M35.6 reviews the source-only 3D generator skeleton and generic parameter config together. The review confirms the current flow remains dry-run-only, does not run Blender, and does not generate assets.

M35.7 plans a future guarded generation drill but still does not run Blender.
M35.8 defines future sidecar expectations while dry-run output remains non-generating.

## Dry-Run Commands

```bash
python3 apps/3d-generator/generic_parametric_blender.py --dry-run
python3 apps/3d-generator/generic_parametric_blender.py --config configs/3d/generic-object.example.json --dry-run
```

## Plan JSON Commands

```bash
python3 apps/3d-generator/generic_parametric_blender.py --plan-json
python3 apps/3d-generator/generic_parametric_blender.py --config configs/3d/generic-object.example.json --plan-json
```

## Config Dry-Run Commands

The config dry-run validates `configs/3d/generic-object.example.json`, reports the asset summary, and keeps `runtime_assets_written` false.

## Negative `REAL_3D_GENERATION=1` Behavior

The review script runs:

```bash
REAL_3D_GENERATION=1 python3 apps/3d-generator/generic_parametric_blender.py --plan-json
```

Expected behavior:

- `real_generation_requested` is true.
- `real_generation_enabled` is true.
- `runtime_assets_written` remains false.
- `generation_triggered` remains false.
- the script still reports that real generation is not implemented.

## Non-JSON Config Rejection

The review script creates a temporary `.txt` config under `/tmp` and verifies that `--config` rejects it because configs must use `.json`.

## Safety Flags

The review validates:

- `dry_run`: `true`
- `blender_execution_attempted`: `false`
- `runtime_assets_written`: `false`
- `source_assets_modified`: `false`
- `generation_triggered`: `false`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`

## No Generated Assets

The review checks that no `.blend`, `.glb`, `.obj`, `.fbx`, or `.mtl` files exist under the repo.

## How To Test

```bash
make check-layout
make check-python-syntax
bash -n scripts/test-3d-dry-run-review.sh
make test-3d-dry-run-review
```

## Why This Is Still Not Blender Execution

The review uses normal Python only. The skeleton does not import `bpy` at module import time, does not invoke Blender, and does not write runtime assets.
