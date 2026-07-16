# Blender Adapter Implementation

## What Was Implemented

M35.14 adds a source-only Blender adapter planning layer.

M35.15 uses Blender operation plans as input to the future guarded generation drill.

The adapter converts generic primitive scene plans into deterministic Blender operation plans without running Blender or importing `bpy` at module import time.

## Blender Adapter Plan Layer

The adapter lives in:

```text
apps/3d-generator/blender_adapter.py
```

It is importable with normal Python and uses only the standard library.

## No Module-Level bpy Import

`blender_adapter.py` does not import `bpy` at module import time.

The optional guarded execution function imports `bpy` only inside the function and is not called by tests.

## Operation Plan JSON

Use:

```bash
python3 apps/3d-generator/generic_parametric_blender.py \
  --config configs/3d/generic-object.example.json \
  --blender-operation-plan-json
```

This prints:

- `plan_type`
- `asset_name`
- `asset_category`
- `operation_count`
- `operation_types`
- `operations`
- `safety_flags`

## Primitive-to-Operation Mapping

- `rectangular_prism` -> `create_cube`
- `cylinder` -> `create_cylinder`
- `plane` -> `create_plane`
- `sloped_plane` -> `create_plane`
- `frame` -> `create_cube`
- `panel` -> `create_cube`
- `connector_placeholder` -> `create_empty`
- `guide_line` -> `create_empty`
- `label_anchor` -> `create_empty`

## Object Name Sanitization

Object names are deterministic.

Letters, numbers, dash, and underscore are preserved. Spaces and unsafe characters become underscores. Empty names are prefixed with `object_`.

## Safety Flags

Operation plans report:

- `bpy_imported` false
- `blender_execution_attempted` false
- `runtime_assets_written` false
- `generation_triggered` false
- `source_assets_modified` false

## No Runtime Writes

M35.14 does not write runtime files, metadata sidecars, reports, generated assets, or previews.

## No Blender Execution In Tests

Tests run with normal Python only.

They do not run Blender, install Blender, import `bpy`, or create `.blend`, `.glb`, `.obj`, `.fbx`, or `.mtl` files.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-blender-adapter
```

Expected:

- Blender operation plan JSON is valid
- plan summary appears in `--plan-json`
- unsupported primitive types are rejected through the config/scene plan path
- no generated 3D files appear in the repo

## Fixed Roadmap

Next milestone: M35.15 First Guarded Local Blender Generation Drill.

- M35.15 First Guarded Local Blender Generation Drill
- M35.16 Generated 3D Artifact Verification
- M35.17 3D Output Card API
- M35.18 Dashboard 3D Output Cards UI
- M35.19 3D Reference Board Selection
- M35.20 M35 Phase Closure
