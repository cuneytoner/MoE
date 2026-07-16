# Guarded Blender Generation Implementation

## What Was Implemented

M35.10 adds guarded real-generation code paths to the generic 3D generator while keeping the default behavior dry-run-only.

The script now supports:

- `REAL_3D_GENERATION=1`
- `--execute-generation`
- a `generation_guard` block in plan JSON
- clean failure outside Blender when both generation guards are supplied

No generated 3D assets are created in this milestone.

## Why bpy Is Imported Only Inside Guarded Generation

The generator must remain testable with normal Python. Importing `bpy` at module import time would make dry-run tests depend on Blender being installed.

`bpy` is imported only inside the guarded generation function after config and path validation pass and after both generation guards are present.

## Required Guards

Future Blender execution requires all of these:

- `REAL_3D_GENERATION=1`
- `--execute-generation`
- valid config
- runtime output root under `/home/cuneyt/MoE/runtime/media/outputs/3d`
- Blender/bpy availability

`REAL_3D_GENERATION=1` alone does not execute generation.

`--execute-generation` alone fails before generation.

## Dry-Run Behavior

Default behavior remains dry-run.

Dry-run plan JSON reports:

- `generation_guard.execute_generation_requested` as `false`
- `generation_guard.real_generation_env_enabled` as `false`
- `generation_guard.all_generation_guards_passed` as `false`
- `safety_flags.runtime_assets_written` as `false`
- `safety_flags.generation_triggered` as `false`

## REAL_3D_GENERATION=1 Without Execute Behavior

When `REAL_3D_GENERATION=1` is set without `--execute-generation`, the script still writes no files and does not execute Blender.

Plan JSON may show:

- `real_generation_env_enabled` as `true`
- `execute_generation_requested` as `false`
- `all_generation_guards_passed` as `false`

## Execute Without REAL_3D_GENERATION Behavior

When `--execute-generation` is supplied without `REAL_3D_GENERATION=1`, the script exits non-zero with:

```text
real generation requires REAL_3D_GENERATION=1
```

No files are written.

## Outside-Blender Failure Behavior

When both `REAL_3D_GENERATION=1` and `--execute-generation` are supplied outside Blender, the script exits non-zero with a controlled error because `bpy` is unavailable.

The default failure does not print a traceback.

No files are written.

## Safety Flags

Dry-run and plan modes keep:

- `blender_execution_attempted` false
- `runtime_assets_written` false
- `source_assets_modified` false
- `generation_triggered` false

## No Generated Assets In This Milestone

M35.10 does not run Blender, install Blender, render previews, or create `.blend`, `.glb`, `.obj`, `.fbx`, `.mtl`, image, video, sidecar, or runtime asset files.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-generation-guards
```

### Run on PC-1

```bash
make test-3d-dry-run-review
```

Expected:

- dry-run succeeds
- plan JSON includes `generation_guard`
- `REAL_3D_GENERATION=1` without `--execute-generation` stays non-generating
- `--execute-generation` without `REAL_3D_GENERATION=1` fails cleanly
- both guards outside Blender fail cleanly
- no generated 3D files appear in the repo
