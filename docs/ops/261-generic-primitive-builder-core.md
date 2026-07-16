# Generic Primitive Builder Core

## What Was Implemented

M35.13 adds a Blender-independent primitive builder core for future generic 3D generation.

M35.14 adds a Blender adapter operation-plan layer on top of scene plans without executing Blender.

The builder converts validated config components into deterministic scene plan dictionaries. It does not import Blender, write files, or create runtime assets.

## Blender-Independent Primitive Builder

The primitive builder lives in:

```text
apps/3d-generator/primitive_builder.py
```

It uses only Python standard library modules and is importable with normal Python.

## Supported Primitive Types

- `rectangular_prism`
- `cylinder`
- `plane`
- `sloped_plane`
- `frame`
- `panel`
- `connector_placeholder`
- `guide_line`
- `label_anchor`

## Scene Plan JSON

The scene plan has:

- `plan_type`
- `asset_name`
- `asset_category`
- `units`
- `coordinate_system`
- `primitive_count`
- `primitive_types`
- `primitives`
- `safety_flags`

Every primitive is marked with:

```text
generation_status: planned_only
```

## Validation Behavior

The builder validates:

- component ids
- component types
- duplicate component ids
- position vector fields
- rotation vector fields
- required dimensions by primitive type
- finite positive numeric dimensions

Invalid configs fail before generation and produce no files.

## CLI Usage

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
python3 apps/3d-generator/generic_parametric_blender.py \
  --config configs/3d/generic-object.example.json \
  --scene-plan-json
```

This prints the scene plan to stdout.

## Safety Flags

Scene plans report:

- `blender_required` false
- `bpy_imported` false
- `runtime_assets_written` false
- `generation_triggered` false
- `source_assets_modified` false

## No Runtime Writes

M35.13 does not write runtime files, metadata sidecars, reports, generated assets, or previews.

## No Blender Execution

M35.13 does not run Blender, install Blender, import `bpy`, or create `.blend`, `.glb`, `.obj`, `.fbx`, or `.mtl` files.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-primitive-builder
```

Expected:

- scene plan JSON is valid
- scene plan summary appears in `--plan-json`
- duplicate component ids are rejected
- unsupported component types are rejected
- no generated 3D files appear in the repo

## Fixed Roadmap

Next milestone: M35.14 Blender Adapter Implementation.

- M35.14 Blender Adapter Implementation
- M35.15 First Guarded Local Blender Generation Drill
- M35.16 Generated 3D Artifact Verification
- M35.17 3D Output Card API
- M35.18 Dashboard 3D Output Cards UI
- M35.19 3D Reference Board Selection
- M35.20 M35 Phase Closure
