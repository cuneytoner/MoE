# Guarded Blender Animation Implementation

M36.7 adds a Blender animation adapter that converts reviewed M36.2 canonical animation plans plus M36.3 timeline/keyframe plans into deterministic Blender operation plans.

## What Was Implemented

- Source file: `apps/media-worker/app/blender_animation_adapter.py`
- Request schema: `configs/animation/blender-animation-adapter-request.schema.json`
- Example request: `configs/animation/blender-animation-adapter-request.example.json`
- Regression: `scripts/test-blender-animation-adapter.sh`

The adapter is importable in normal Python. It builds, validates, and reports a Blender operation plan without requiring Blender.

## Validator And Timeline Reuse

The adapter reuses M36.2 validation through `validate_animation_plan_structure(...)` and `validate_animation_plan_semantics(...)`.

It reuses M36.3 timeline planning through `build_timeline_keyframe_plan(...)` and `canonical_plan_hash(...)`.

The request is rejected when:

- the canonical plan fails M36.2 validation
- `timeline_plan.source_plan_sha256` does not match the canonical plan hash
- the supplied timeline plan differs from the rebuilt M36.3 timeline plan

## Operation Plan Behavior

The operation plan is deterministic and uses this order:

1. `configure_scene_timeline`
2. `resolve_target`
3. `set_rotation_mode`
4. `set_camera_lens`
5. `set_transform_values`
6. `set_visibility_value`
7. `insert_transform_keyframe`
8. `insert_visibility_keyframe`
9. `set_fcurve_interpolation`

Operation ids are deterministic and match `^[a-z0-9][a-z0-9-]*$`.

## Target Resolution

Target resolution uses only `bpy.data.objects.get(target_id)`.

Object targets must exist. Camera targets must exist and have Blender type `CAMERA`. The adapter does not create, rename, duplicate, or search for similar targets.

## Timeline Mutation

Guarded execution mutates only:

- `scene.render.fps`
- `scene.frame_start`
- `scene.frame_end`

Render settings, output paths, codecs, resolution, and save behavior are out of scope.

## Animation Mutation

Transform animation is limited to:

- `location`
- `rotation_euler`
- `scale`

Targets using `rotation_euler` receive `rotation_mode = "XYZ"` before keyframes are inserted.

Visibility animation is object-only. `visible=true` maps to `hide_viewport=false` and `hide_render=false`; `visible=false` maps both to `true`.

Camera lens settings are static only, finite, and constrained to `1.0..300.0`.

Interpolation maps to Blender constants:

- `constant -> CONSTANT`
- `linear -> LINEAR`
- `bezier -> BEZIER`

## Execution Guards

Normal CLI behavior is plan-only:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
python3 apps/media-worker/app/blender_animation_adapter.py \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --pretty
```

Guarded execution requires both:

```bash
REAL_ANIMATION_GENERATION=1
--execute-animation
```

`REAL_ANIMATION_GENERATION=1` without `--execute-animation` remains plan-only.

`--execute-animation` without `REAL_ANIMATION_GENERATION=1` exits with code `2`.

Execution outside Blender exits with code `2` and a controlled `blender_unavailable` report.

## Import Boundary

The adapter has no module-level `bpy` or `mathutils` import. The only `bpy` import is inside `execute_blender_animation_operation_plan(...)`.

The private `_execute_with_bpy_module(...)` helper exists so regressions can validate execution semantics with fake Blender objects.

## What Is Not Implemented

M36.7 does not implement:

- preview rendering
- video encoding
- frame export
- `.blend` save
- asset import or export
- object creation, deletion, rename, or duplication
- metadata sidecar writing
- Gateway endpoints
- Dashboard UI
- Docker changes

M36.8 adds animation metadata sidecar writing as a separate source-only writer. The M36.7 adapter still does not write metadata sidecars itself.

## How To Test

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
make test-blender-animation-adapter
```

Expected:

- plan-only report exits `0`
- missing guard exits `2`
- env-only remains plan-only
- fake Blender execution mutates only timeline/target animation fields
- no runtime files or generated media appear in the repo
