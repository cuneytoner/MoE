# Blender Animation Adapter Plan

## Purpose

M36.6 defined the future Blender animation adapter contract without implementing a Python adapter. M36.7 implements that reviewed contract in `apps/media-worker/app/blender_animation_adapter.py` while keeping normal operation plan-only.

## Scope

This milestone is plan-only. It defines input envelopes, target resolution, operation types, ordering, failure behavior, and execution guard requirements for future implementation.

## Non-Goals

M36.6 did not add `apps/media-worker/app/blender_animation_adapter.py`, `apps/media-worker/app/animation_blender_adapter.py`, `bpy` imports, `mathutils` imports, Blender execution, keyframe insertion, preview rendering, ffmpeg, runtime writes, Gateway endpoints, Dashboard UI, Docker services, or generated media. M36.7 adds the adapter with local-only `bpy` import inside the guarded execution function and still does not add rendering, runtime asset writes, Gateway endpoints, Dashboard UI, Docker services, or generated media.

## Existing M35 Adapter Lessons

M35 established the source-only pattern:

```text
domain plan
-> deterministic Blender operation plan
-> guarded Blender execution
```

The M35 adapter remains importable without Blender. M36 should keep the same separation: operation planning must run in normal Python, while any future `bpy` import belongs only inside guarded execution.

## Adapter Input Envelope

Planned request shape:

```json
{
  "schema_version": "1.0",
  "request_type": "blender_animation_adapter_request",
  "source_kind": "camera_animation_plan",
  "source_request_sha256": "<64 hex>",
  "canonical_animation_plan": {},
  "timeline_plan": {},
  "planner_context": {
    "camera_settings": {
      "camera_id": "camera",
      "lens_mm": 50.0
    }
  },
  "safety": {
    "real_animation_enabled": false,
    "blender_execution_enabled": false,
    "runtime_write_planned": false
  }
}
```

Allowed `source_kind` values:

- `camera_animation_plan`
- `object_transform_animation_plan`

## Canonical Animation Plan Input

`canonical_animation_plan` must be a M36 canonical animation plan that has passed M36.2 validation. The adapter must not accept arbitrary track shapes, arbitrary data paths, Python expressions, or unchecked runtime paths.

## Timeline Plan Input

`timeline_plan` must be produced by the M36.3 timeline/keyframe planner from the same canonical plan. The adapter must reject mismatched plan ids, timeline values, track ids, keyframe counts, or plan hashes.

## Optional Planner Context

Camera planner context may include static `camera_settings` such as `camera_id` and `lens_mm`. Object planner context may be an empty object.

Planner context must not contain runtime filesystem paths, Blender object references, arbitrary Python expressions, environment values, or host-specific state.

## Target Resolution Contract

Adapter operation plans use stable:

```text
target_type
target_id
```

Allowed target types:

- `camera`
- `object`

M36.6 performed no target resolution. M36.7 resolves camera targets with `bpy.data.objects.get(target_id)` and verifies `object.type == CAMERA`. Object targets also use `bpy.data.objects.get(target_id)` and require existence.

If a target cannot be resolved, future implementation must not create a new object, guess a target name, use the first camera, or use the active object fallback. It should return a controlled failure.

Target creation is forbidden; every `resolve_target` operation must use `create_if_missing=false`.

Planned target errors:

- `target_not_found`
- `target_type_mismatch`
- `duplicate_target_resolution`
- `unsupported_target_type`

## Operation Plan Contract

Example operation plan:

```text
configs/animation/blender-animation-operation-plan.example.json
```

The shape is:

```json
{
  "schema_version": "1.0",
  "plan_type": "blender_animation_operation_plan",
  "status": "planned",
  "source_plan_id": "camera-orbit-demo-plan",
  "source_plan_sha256": "<64 hex>",
  "operation_count": 0,
  "operation_types": [],
  "operations": [],
  "safety_flags": {
    "bpy_imported": false,
    "blender_execution_attempted": false,
    "runtime_assets_written": false,
    "source_assets_modified": false,
    "keyframes_written": false,
    "scene_modified": false,
    "external_process_started": false
  }
}
```

## Supported Operation Types

Allowed operation types:

- `configure_scene_timeline`
- `resolve_target`
- `set_rotation_mode`
- `set_camera_lens`
- `set_transform_values`
- `set_visibility_value`
- `insert_transform_keyframe`
- `insert_visibility_keyframe`
- `set_fcurve_interpolation`

Forbidden operation types:

- `create_object`
- `delete_object`
- `rename_object`
- `duplicate_object`
- `import_asset`
- `export_asset`
- `save_blend`
- `render_frame`
- `render_animation`
- `run_ffmpeg`
- `execute_python`
- `run_operator`
- `run_shell`

## Operation Ordering

Deterministic order:

1. `configure_scene_timeline`
2. `resolve_target` operations in first-seen source track order
3. `set_rotation_mode` for targets using `rotation_euler`
4. `set_camera_lens` when camera planner context provides a static lens
5. keyframe value and insertion operations in source track/keyframe order
6. `set_fcurve_interpolation` operations

Canonical track order and keyframe order must be preserved. Targets must not be alphabetically sorted. If the same target appears in multiple tracks, `resolve_target` is planned once at first sight using deterministic deduplication.

## Timeline Setup

Planned operation:

```json
{
  "operation_id": "configure-scene-timeline",
  "operation_type": "configure_scene_timeline",
  "fps": 24,
  "start_frame": 1,
  "end_frame": 120
}
```

M36.7 limits implementation to `scene.render.fps`, `scene.frame_start`, and `scene.frame_end`. Resolution, render engine, output path, and codec settings stay out of scope.

## Camera Settings

When camera planner context includes a static lens:

```json
{
  "operation_id": "set-camera-lens-camera",
  "operation_type": "set_camera_lens",
  "target_type": "camera",
  "target_id": "camera",
  "lens_mm": 50.0,
  "animated": false
}
```

Lens values must be finite and in the `1..300` range. Lens is not keyframed. Lens operations apply only to camera targets. The adapter must not invent lens values from the canonical animation plan.

## Transform Keyframes

Each transform keyframe first plans a value operation:

```json
{
  "operation_id": "set-transform-camera-frame-1",
  "operation_type": "set_transform_values",
  "target_type": "camera",
  "target_id": "camera",
  "frame": 1,
  "values": {
    "location": [0.0, -5.0, 3.0],
    "rotation_euler": [1.0, 0.0, 0.0]
  }
}
```

Only fields present in the keyframe may be carried:

- `location`
- `rotation_euler`
- `scale`

Missing values must not be invented.

Each animated transform field may then create a separate insertion operation with an allowed `data_path`:

- `location`
- `rotation_euler`
- `scale`

## Visibility Keyframes

Canonical visibility tracks plan value operations:

```json
{
  "operation_id": "set-visibility-demo-object-frame-1",
  "operation_type": "set_visibility_value",
  "target_type": "object",
  "target_id": "demo-object",
  "frame": 1,
  "visible": true,
  "blender_properties": ["hide_viewport", "hide_render"]
}
```

Visibility mapping:

```text
visible=true:
  hide_viewport=false
  hide_render=false

visible=false:
  hide_viewport=true
  hide_render=true
```

Keyframe insertion uses:

```json
{
  "operation_type": "insert_visibility_keyframe",
  "data_paths": ["hide_viewport", "hide_render"]
}
```

M36.6 does not execute these operations.

## Interpolation Assignment

Track interpolation maps to Blender names:

```text
constant -> CONSTANT
linear   -> LINEAR
bezier   -> BEZIER
```

Planned operation:

```json
{
  "operation_id": "set-interpolation-camera-transform",
  "operation_type": "set_fcurve_interpolation",
  "target_type": "camera",
  "target_id": "camera",
  "source_track_id": "camera-camera-transform",
  "interpolation": "BEZIER"
}
```

Bezier handles, easing, automatic handle type, FCurve modifiers, extrapolation, and sampled curves are deferred.

## Rotation Mode

Targets using canonical `rotation_euler` require:

```json
{
  "operation_id": "set-rotation-mode-camera",
  "operation_type": "set_rotation_mode",
  "target_type": "camera",
  "target_id": "camera",
  "rotation_mode": "XYZ"
}
```

M36.6 only plans `XYZ`. Quaternion, axis-angle, and custom Euler order support are deferred.

## Failure Handling

Planned stop codes:

- `adapter_request_invalid`
- `canonical_plan_invalid`
- `timeline_plan_invalid`
- `plan_hash_mismatch`
- `timeline_mismatch`
- `unsupported_operation`
- `duplicate_operation_id`
- `target_not_found`
- `target_type_mismatch`
- `unsupported_data_path`
- `invalid_frame`
- `invalid_transform_value`
- `invalid_interpolation`
- `camera_settings_invalid`

Fail fast before mutation. If validation, target resolution, or preflight fails, no keyframes should be written and no scene mutation should occur. The future implementation must not claim automatic rollback.

## Safety Guards

M36.7 execution must require both:

```text
REAL_ANIMATION_GENERATION=1
--execute-animation
```

Execution may start only when the environment guard is true, the CLI guard is true, the process is running inside Blender, adapter request validation passes, the canonical plan and timeline plan validate, all targets resolve, and every operation is preflighted.

Preview rendering remains out of scope. `--render-preview` must be handled by a later milestone.

## Blender Import Boundary

`bpy` must not be imported at module level. In M36.7, it may only be imported inside the guarded execution function. Source-only tests must run without Blender installed, and import failure must produce a controlled error.

## Runtime Boundaries

M36.6 does not create runtime folders, write runtime plans, write metadata, save `.blend`, write previews, write frames, or mutate objects/scenes. Runtime artifact export and preview render remain later milestones.

## Determinism

Operation ids must match:

```text
^[a-z0-9][a-z0-9-]*$
```

Ids must be unique, deterministic, and derived from operation type, target id, source track id, and frame when relevant. They must not include UUIDs, timestamps, paths, or environment data.

## M36.7 Implementation Contract

M36.7 implements the adapter after this plan was reviewed. It builds operation plans without Blender, preflights everything before mutation, requires the two execution guards, and imports `bpy` only inside guarded execution.

## Test Strategy

Run:

```bash
make test-blender-animation-adapter-plan
```

The M36.6 regression checks the plan docs, example JSON, operation allowlist, forbidden operations, ordering, target resolution rules, safety flags, guards, import boundary, runtime boundary, roadmap status, no generated media, and M36.8 non-start.

## Final Decision

M36.6 is DONE when the plan, review template, example operation plan, layout requirements, roadmap updates, and source-only regression pass. M36.7 is implemented separately by 291 and 292. M36.8 remains planned.
