# Preview Render Safety Plan

## Purpose

M36.10 defines the safety contract for future animation preview rendering. It does not implement rendering. The first future implementation target for M36.11 is a deterministic sampled PNG frame sequence, not video.

## Scope

This milestone adds a source-only preview request schema, a source-only preview request example, a source-only operation plan example, this safety plan, a review template, and regression checks.

## Non-goals

M36.10 does not add `bpy` imports, Blender execution, frame rendering, video encoding, `ffmpeg`, subprocess calls, preview file writes, runtime directory creation, `.blend` saves, Gateway endpoints, Dashboard changes, Docker services, or M36.11 implementation code.

## Existing Animation Pipeline Integration

The future preview renderer must build on the existing M36 layers:

- M36.2 canonical animation plan validation.
- M36.3 timeline/keyframe planning and deterministic hashing.
- M36.7 Blender animation adapter request validation and operation planning.
- M36.8 metadata sidecar hashing conventions.
- M36.9 metadata validator provenance checks.

Preview rendering must not bypass M36.7 execution guards. It must validate the preview request first, revalidate the adapter request, rebuild the canonical/timeline/operation plan, and compare request hashes before any scene mutation or render begins.

## Preview Request Contract

The source-only request schema is:

```text
configs/animation/preview-render-request.schema.json
```

The source-only example is:

```text
configs/animation/preview-render-request.example.json
```

Fixed fields:

- `schema_version = "1.0"`
- `request_type = "animation_preview_render_request"`
- `render_mode = "sampled_frames"`
- `render.engine = "BLENDER_EEVEE_NEXT"`
- `render.format = "PNG"`
- `output.overwrite_existing = false`

Request safety fields are documentation and validation signals only. They never grant execution permission.

## Source And Hash Validation

Allowed `source_kind` values:

- `camera_animation_plan`
- `object_transform_animation_plan`

Hash fields must be exactly 64 lowercase hex characters:

- `source_request_sha256`
- `canonical_plan_sha256`

M36.11 must reload and validate the adapter request, rebuild the canonical plan hash, and compare both hashes before any scene mutation or render starts. Any mismatch is a controlled failure.

## Camera Resolution

The request must contain an explicit safe `camera_id`.

M36.11 must resolve the camera with:

```text
bpy.data.objects.get(camera_id)
```

The resolved object type must be `CAMERA`.

Forbidden fallbacks:

- scene camera
- active object
- selected object
- first camera
- name similarity
- automatic camera creation

If the camera is missing or is not a camera, preflight fails.

## Frame Selection

M36.11 renders sampled PNG frames only.

The timeline values come from the validated canonical/timeline plan:

- `start_frame`
- `end_frame`
- `total_frames`

For `N = sample_count`, frame `i` is selected with:

```python
frame_i = start_frame + (i * (end_frame - start_frame)) // (N - 1)
```

Rules:

- `sample_count >= 2`
- `sample_count <= 24`
- `sample_count <= total_frames`
- first frame equals `start_frame`
- last frame equals `end_frame`
- frames are strictly increasing
- duplicate frames fail validation
- no random sampling
- no floating-point rounding
- `include_start_frame` and `include_end_frame` are both `true` in the first version

## Frame Limits

The maximum frame count is 24. The preview request cannot request more than 24 frames, and the future implementation must reject requests where `sample_count > total_frames`.

## Resolution And Pixel Limits

Initial limits:

- minimum width: 64
- maximum width: 1920
- minimum height: 64
- maximum height: 1080
- resolution percentage: 100
- maximum total pixel budget: 49,766,400 pixels

The pixel budget formula is:

```text
total_pixel_budget = sample_count * width * height
```

The maximum matches:

```text
24 * 1920 * 1080
```

Boolean values must be real booleans, not integers or numbers.

## Render Engine Allowlist

The first allowlist contains only:

```text
BLENDER_EEVEE_NEXT
```

Unsupported for M36.11:

- `CYCLES`
- `BLENDER_WORKBENCH`
- custom engine identifiers
- user-provided arbitrary engine names

If EEVEE Next is unavailable, M36.11 must return a controlled error. It must not fallback to another engine.

## Render Settings Boundary

M36.11 may temporarily change only:

- `scene.render.engine`
- `scene.render.resolution_x`
- `scene.render.resolution_y`
- `scene.render.resolution_percentage`
- `scene.render.image_settings.file_format`
- `scene.render.film_transparent`
- `scene.render.filepath`
- `scene.camera`

M36.11 must not change color management, arbitrary sampling settings, world settings, compositor nodes, codecs, audio, render devices, GPU preferences, scene units, frame rate, animation keyframes, materials, lights, or objects outside M36.7 adapter operations.

Before changing settings, M36.11 must snapshot them. Success and failure paths must restore settings in `finally`.

## M36.7 Execution Relationship

Preview rendering must not automatically apply a new animation unless all M36.7 and preview guards are present.

Required future order:

1. preview request validation
2. adapter request validation
3. canonical plan validation
4. timeline validation
5. operation plan validation
6. camera resolution
7. deterministic frame selection
8. output preflight
9. render settings snapshot
10. M36.7 guarded animation execution
11. sampled preview render
12. render settings restore
13. result report

## Execution Guards

M36.11 must require all four guards:

```text
REAL_ANIMATION_GENERATION=1
REAL_ANIMATION_PREVIEW_RENDER=1
--execute-animation
--render-preview
```

If any one is missing, runtime writes and rendering must not start.

## Runtime Output Root

The fixed animation runtime root is:

```text
/home/cuneyt/MoE/runtime/media/animation
```

The fixed preview root is:

```text
/home/cuneyt/MoE/runtime/media/animation/previews
```

The future final frame directory is:

```text
/home/cuneyt/MoE/runtime/media/animation/previews/<preview-id>/frames
```

M36.10 does not create these directories.

## Output Path Safety

The request carries only a POSIX runtime-relative directory:

```text
media/animation/previews/<preview-id>/frames
```

Rules:

- no leading slash
- no backslash
- no `.` segment
- no `..` segment
- no URL scheme
- no drive prefix
- no repo marker
- no model backup marker
- directory id must match `preview_id`

The filename pattern is fixed:

```text
frame-{frame:06d}.png
```

Arbitrary format strings are not accepted.

## Staging Behavior

M36.11 must not render directly into the final directory. It should render to a verified staging directory under the approved preview root, such as:

```text
/home/cuneyt/MoE/runtime/media/animation/previews/.staging/<preview-id>-<safe-run-token>
```

The run token must not become canonical metadata. A process-local temporary staging directory is also acceptable if it remains under the approved preview root.

Staging cleanup must only touch the verified staging path for the current job.

## Atomic Publish

After every frame is rendered and verified, M36.11 may atomically rename the staging frame directory to the final directory.

Rules:

- final directory already exists -> fail
- no partial final publish
- staging must stay under the approved preview root
- staging must not be a symlink
- failure cleanup must not delete any other job directory

## Overwrite Policy

`overwrite_existing` is fixed to `false`. Existing final output is a controlled failure. No overwrite, merge, or delete behavior is allowed.

## Output Size Limit

M36.11 must verify each rendered frame:

- exists
- regular file
- not symlink
- `.png` extension
- size greater than zero

The total size must satisfy:

```text
sum(frame sizes) <= 536870912
```

That is 512 MiB. If the limit is exceeded, final publish must not happen and staging must be safely cleaned.

## Timeout Behavior

M36.11 must not start subprocesses. It runs inside Blender, so timeout handling must use elapsed monotonic time.

Timeout checks must happen before and after each frame. If the timeout is exceeded, no new frame render should start. A render already in progress may not be hard-cancelable; this limitation must be reported honestly.

Maximum timeout is 300 seconds.

## Failure And Partial Behavior

Failure report fields should include:

- `status = failed`
- `final_output_published = false`
- `partial_output_available = false`
- `render_settings_restored = true` or `false`

Partial frame directories must not be published as final output. M36.11 must not retry automatically and must not reduce resolution, reduce frames, or change render engine as fallback.

## Preview Report

M36.10 report status is `planned` because no output is created.

Future successful report shape:

```json
{
  "schema_version": "1.0",
  "report_type": "animation_preview_render",
  "status": "rendered",
  "preview_id": "object-transform-demo-preview",
  "render_mode": "sampled_frames",
  "engine": "BLENDER_EEVEE_NEXT",
  "format": "PNG",
  "width": 1280,
  "height": 720,
  "frames": [1, 18, 35, 52, 69, 86, 103, 120],
  "frame_count": 8,
  "relative_output_directory": "media/animation/previews/object-transform-demo-preview/frames",
  "total_output_bytes": 0,
  "execution": {
    "animation_applied": true,
    "preview_rendered": true,
    "video_encoded": false,
    "blend_file_saved": false
  },
  "safety_flags": {
    "runtime_assets_written": true,
    "source_assets_modified": false,
    "preview_render_attempted": true,
    "external_process_started": false,
    "ffmpeg_started": false,
    "video_written": false,
    "blend_file_saved": false,
    "render_settings_restored": true
  }
}
```

## Blender Import Boundary

M36.10 adds no new Python implementation. M36.11 may import `bpy` only inside the guarded execution path, following the M36.7 import boundary. No `mathutils` import is planned.

## No-ffmpeg Boundary

M36.11 must not call external `ffmpeg`, Blender FFMPEG encoding, MP4, WebM, GIF, audio, muxing, or production render flows.

The canonical animation plan may still keep MP4/WebM/GIF preview paths as future encode targets. M36.11 must not produce them.

## M36.11 Implementation Contract

M36.11 implements guarded sampled PNG preview frames after this plan. The default behavior remains plan-only.

It must not add Gateway or Dashboard behavior. It must not accept arbitrary output roots. It must not treat request safety fields as execution guards.

## Test Strategy

Regression checks must avoid internet, Docker, Blender, node/npm, runtime services, model runtime, runtime writes, and generated preview assets.

They verify schema constants, JSON examples, docs, roadmap status, guard documentation, output path policy, no `bpy`/`mathutils` imports, no implementation source, no runtime directory creation, and no generated frame/video artifacts.

## Final Decision

M36.10 is approved as a source-only preview render safety plan. M36.11 implements the guarded sampled PNG renderer without adding video, Gateway, Dashboard, Docker, or artifact-verifier behavior.
