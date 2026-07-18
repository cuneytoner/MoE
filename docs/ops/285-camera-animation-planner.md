# Camera Animation Planner

## Purpose

M36.4 adds a source-only deterministic camera planner. It accepts a strict camera motion request, supports the first motion type (`orbit`), generates deterministic camera poses, builds a canonical M36 animation plan, validates it through M36.2, and plans it through M36.3.

It does not parse free text, call an LLM, resolve runtime targets, import Blender, create constraints, write keyframes, render previews, call ffmpeg, write runtime files, expose Gateway endpoints, or change Dashboard UI.

## Planner Source

Planner source:

```text
apps/media-worker/app/camera_animation_planner.py
```

## Camera Request Schema

The camera request schema is:

```text
configs/animation/camera-motion.schema.json
```

It uses JSON Schema Draft 2020-12 and pins the schema id to:

```text
urn:moe:camera-motion-schema:1.0
```

## Example Request

The source-only example request is:

```text
configs/animation/camera-orbit.example.yaml
```

It describes a dry-run camera orbit around a fixed world-space center.

## Relationship To M36.2 Validator

The camera planner has its own strict camera request validation. After generating the canonical animation plan, it reuses M36.2 animation plan validation. If the generated canonical plan does not pass M36.2, the camera planner fails safely.

## Relationship To M36.3 Timeline Planner

After M36.2 validation passes, the planner reuses M36.3 `build_timeline_keyframe_plan` to prove that the generated camera plan can move through the generic timeline/keyframe layer.

## Supported Motion

M36.4 supports only:

```text
motion.type = orbit
motion.orientation = look_at_center
```

## Coordinate Convention

- world handedness: right-handed
- world up axis: `+Z`
- orbit plane: `XY`
- request angles: degrees
- output `rotation_euler`: radians
- Euler order: `XYZ`
- camera local forward axis: `-Z`
- camera local up axis: `+Y`
- positive orbit angle: counter-clockwise viewed from `+Z`
- angle 0 degrees: `center + [radius, 0, height_offset]`

## Frame Distribution

For `N = keyframe_count` and `span = end_frame - start_frame`:

```text
frame_i = start_frame + (i * span) // (N - 1)
```

The first pose is always `start_frame`; the last pose is always `end_frame`.

## Angle Distribution

For each pose:

```text
fraction = i / (N - 1)
angle_degrees = start + fraction * (end - start)
angle_radians = radians(angle_degrees)
```

Values are rounded to 9 decimal places and negative zero is normalized.

## Orbit Positions

For each angle:

```text
x = center_x + radius * cos(angle_radians)
y = center_y + radius * sin(angle_radians)
z = center_z + height_offset
```

The planner does not mutate request center values or add default transform fields.

## Look-At Euler Calculation

For a pose and fixed center:

```text
dx = center_x - camera_x
dy = center_y - camera_y
dz = center_z - camera_z
horizontal = sqrt(dx^2 + dy^2)
rotation_x = atan2(horizontal, -dz)
rotation_y = 0.0
rotation_z = atan2(dy, dx) - pi / 2
```

`rotation_z` is normalized into a stable `[-pi, pi]` range. The helper does not import Blender or `mathutils`.

## Lens Plan

The request field `camera.lens_mm` is preserved as static camera settings:

```json
{
  "camera_id": "camera",
  "lens_mm": 50.0,
  "animated": false
}
```

Lens animation is not implemented.

## Canonical Animation Plan Output

The generated canonical animation plan contains one camera transform track. Each keyframe contains only:

- `frame`
- `location`
- `rotation_euler`

The planner does not add object tracks, scale, visibility, lens tracks, constraints, or missing keyframes.

## Camera Planner Output

CLI reports use:

```json
{
  "schema_version": "1.0",
  "report_type": "camera_animation_planner",
  "status": "planned",
  "planned": true,
  "request_path": "configs/animation/camera-orbit.example.yaml",
  "camera_plan": {},
  "errors": [],
  "warnings": [],
  "safety_flags": {}
}
```

## Determinism

The request hash uses canonical JSON serialization with sorted keys, compact separators, UTF-8, and `allow_nan=False`. Output contains no timestamp, UUID, mtime, cwd, environment dump, or absolute host path.

## Mutation Safety

The planner deep-copies request data before producing output and never returns caller-owned request lists or dicts as mutable output.

## CLI

Run:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/camera_animation_planner.py \
  --request configs/animation/camera-orbit.example.yaml \
  --pretty
```

Allowed arguments:

- `--request PATH`
- `--pretty`

## Exit Codes

- `0`: request valid and camera plan produced
- `1`: request loaded, but validation or planning failed
- `2`: path, loading, malformed input, schema, or tooling error

## Safety Flags

Safety flags assert read-only behavior and false values for runtime writes, source mutation, generation, Blender execution, preview rendering, external processes, constraints, keyframe writes, camera creation, and scene modification.

## M36.5 Follow-Up

M36.5 implements the separate object transform animation planner. M36.4 remains camera-only and does not produce object tracks or object-specific motion.

## Deferred Camera Features

Deferred camera features include dolly, truck, pedestal, crane, handheld, arbitrary spline paths, Bezier path geometry, collision avoidance, automatic framing, bounding-box target framing, depth of field, animated lens, focus distance, camera shake, constraint creation, and runtime camera lookup.

## Non-Goals

M36.4 does not implement Blender execution, keyframe writing, preview rendering, runtime output, Gateway endpoints, Dashboard UI, Docker services, or reference-board integration.

## Test Coverage

Run:

```bash
make test-camera-animation-planner
```

The regression covers valid YAML/JSON requests, malformed and invalid inputs, deterministic frame/angle/pose/rotation behavior, canonical plan validation, M36.3 timeline integration, request hashing, mutation safety, safety flags, no Blender/process/runtime behavior, fixture cleanup, and M36.7 non-start.

## Final Decision

M36.4 is DONE when the camera planner, schema, example request, docs, review template, layout requirements, roadmap updates, and source-only regressions pass. M36.5 builds on it with object transform planning; M36.6 adds the adapter plan; M36.7 implements the guarded adapter. M36.8 remains planned.
