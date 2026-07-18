# Guarded Preview Render Implementation

## Purpose

M36.11 implements the M36.10 preview render safety contract. Default behavior is plan-only. Guarded execution can render deterministic sampled PNG frames only when all execution guards are present.

## Implementation source

Source file:

```text
apps/media-worker/app/animation_preview_renderer.py
```

The module is importable in normal Python without Blender.

## Preview request loading

Preview requests are loaded only from:

- `configs/animation/<file>.json`
- `/tmp/<file>.json`

Requests must be UTF-8 JSON objects, regular files, non-symlinks, `.json`, and no larger than 512 KiB. Reports use safe display paths and do not include absolute repo or runtime paths.

## Schema validation

The canonical schema remains:

```text
configs/animation/preview-render-request.schema.json
```

The CLI cannot override the schema path. The implementation performs explicit schema-specific validation for required fields, unknown fields, constants, enums, types, integer bounds, boolean constants, hash patterns, identifier patterns, and nested strictness.

## Adapter request integration

The renderer reuses M36.7 adapter behavior:

- `load_adapter_request`
- `validate_adapter_request`
- `build_blender_animation_operation_plan`
- `validate_blender_animation_operation_plan`
- `_execute_with_bpy_module`

The renderer does not rewrite keyframe application logic.

## Hash validation

The preview request must match the adapter request:

- `source_kind`
- `source_request_sha256`
- `canonical_plan_sha256`

The canonical hash is recomputed from the adapter request canonical animation plan before a preview operation plan is accepted.

## Frame selection

Frame selection is deterministic and integer-only:

```python
frame_i = start_frame + (i * (end_frame - start_frame)) // (sample_count - 1)
```

For the example plan, `start=1`, `end=120`, and `sample_count=8` produce:

```text
1, 18, 35, 52, 69, 86, 103, 120
```

## Preview operation plan

Plan type:

```text
animation_preview_render_operation_plan
```

Operation order:

1. `validate_preview_request`
2. `validate_adapter_request`
3. `resolve_camera`
4. `select_preview_frames`
5. `validate_output_directory`
6. `snapshot_render_settings`
7. `apply_animation_operations`
8. `configure_preview_render`
9. `render_preview_frame`
10. `verify_preview_frame`
11. `restore_render_settings`
12. `publish_preview_directory`

Operation ids are deterministic and unique.

## Plan-only behavior

Default CLI behavior produces an operation plan and exits `0`.

Plan-only behavior does not import Blender, read runtime directories, write runtime directories, create preview files, or inspect runtime output existence.

## Execution guards

Guarded preview execution requires all four guards:

```text
REAL_ANIMATION_GENERATION=1
REAL_ANIMATION_PREVIEW_RENDER=1
--execute-animation
--render-preview
```

Using only one CLI flag exits `2`. Using both CLI flags without both environment guards exits `2`. Environment guards without CLI flags remain plan-only.

## Blender import boundary

`bpy` is imported only inside:

```text
execute_animation_preview_render(...)
```

No module-level `bpy`, `mathutils`, or `subprocess` import exists.

## Preflight

Preflight checks:

- preview request valid
- adapter request valid
- canonical plan valid
- timeline plan valid
- animation operation plan valid
- preview operation plan valid
- hashes match
- frames valid
- pixel budget valid
- camera exists
- camera type is `CAMERA`
- render operator available
- `BLENDER_EEVEE_NEXT` supported
- runtime path remains under preview root
- preview root and parents are not symlinks
- preview-id directory does not already exist

If preflight fails, animation is not applied and preview rendering does not start.

## Camera resolution

Camera resolution uses only:

```text
bpy_module.data.objects.get(camera_id)
```

No scene camera, active object, selected object, first camera, name similarity, or camera creation fallback is used.

## Runtime root

Production root is fixed:

```text
/home/cuneyt/MoE/runtime
```

Preview root is fixed:

```text
/home/cuneyt/MoE/runtime/media/animation/previews
```

The public CLI has no runtime-root override.

## Output path safety

Preview output is resolved from:

```text
media/animation/previews/<preview-id>/frames
```

The path must be POSIX relative, match `preview_id`, end in `/frames`, stay under the preview root, avoid traversal and dot segments, avoid symlink parents, and reject existing preview-id directories.

## Staging

Guarded execution renders into:

```text
previews/<preview-id>/.frames-staging-<process-local-token>/
```

The staging token is not included in reports or metadata.

## Atomic publish

Frames are published only after all frames render and verify. Staging is renamed to `frames` on the same filesystem. Existing final output is never overwritten.

## Render settings snapshot

Before animation or rendering, the renderer snapshots:

- render engine
- resolution
- resolution percentage
- image format
- film transparency
- filepath
- scene camera
- current frame

## Animation execution reuse

After preflight, the renderer applies the M36.7 animation operation plan through:

```text
_execute_with_bpy_module(...)
```

It does not duplicate keyframe insertion or interpolation logic.

## PNG frame rendering

Each selected frame is rendered with:

```text
bpy_module.ops.render.render(write_still=True)
```

The filename is exactly:

```text
frame-000001.png
```

using `frame-{frame:06d}.png`.

## Frame verification

Each rendered frame must exist, be a regular non-symlink `.png`, be non-empty, match the expected filename, and remain inside the staging directory.

## Output size limit

Total frame size is the sum of rendered PNG sizes and must be no more than 536870912 bytes.

## Timeout

The renderer uses monotonic elapsed time. It checks timeout before and after frame renders. It does not use subprocess timeout and does not claim hard cancellation of an in-progress Blender render.

## Render settings restore

Render settings, scene camera, and current frame are restored in `finally`. The report sets `render_settings_restored=true` only when all tracked settings are restored successfully.

## Failure behavior

Failure reports are truthful. If animation was already applied, the report keeps `animation_applied=true` and `scene_modified=true`.

Failures do not publish partial output. Staging is cleaned, and an empty preview-id parent created by the run is removed when safe.

## CLI

Plan-only:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_preview_renderer.py \
  --preview-request configs/animation/preview-render-request.example.json \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --pretty
```

Guarded execution must run inside Blender with all four guards.

## Exit codes

- `0`: plan produced or preview rendered
- `1`: loaded request validation, preflight, render, verification, size, timeout, or publish failure
- `2`: path/load/malformed JSON, inconsistent CLI flags, missing guard, Blender context, or tooling error

## Fake bpy tests

Regression tests use fake bpy objects under `/tmp` to verify successful sampled PNG publication, preflight failures, render failures, verification failures, size limit failures, timeout failures, restore failures, cleanup, and render settings restore.

## No-video boundary

M36.11 does not produce MP4, WebM, GIF, audio, muxed video, Blender FFMPEG output, or external `ffmpeg` output.

## M36.12 boundary

M36.12 Animation Artifact Verifier remains planned. M36.11 verifies frames during the guarded render flow but does not add a separate artifact verifier milestone implementation.

## Final decision

M36.11 implements guarded sampled PNG animation preview rendering with plan-only default behavior and strict execution guards.
