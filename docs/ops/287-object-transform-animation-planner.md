# Object Transform Animation Planner

## Purpose

M36.5 adds a source-only deterministic object transform planner. It accepts a strict object motion request, supports the first motion type (`transform_between`), generates a canonical M36 animation plan, validates that plan through M36.2, and plans it through M36.3.

It does not parse free text, call an LLM, resolve runtime objects, import Blender, create constraints, write keyframes, render previews, call ffmpeg, write runtime files, expose Gateway endpoints, or change Dashboard UI.

## Planner Source

Planner source:

```text
apps/media-worker/app/object_transform_animation_planner.py
```

## Object Request Schema

The object request schema is:

```text
configs/animation/object-motion.schema.json
```

It uses JSON Schema Draft 2020-12 and pins the schema id to:

```text
urn:moe:object-motion-schema:1.0
```

## Example Request

The source-only example request is:

```text
configs/animation/object-transform.example.yaml
```

It describes a dry-run transform between two object states.

## Relationship To M36.2 Validator

The object planner has strict request validation for object-specific fields. After generating the canonical animation plan, it reuses M36.2 animation plan validation. If the generated canonical plan does not pass M36.2, the object planner fails safely.

## Relationship To M36.3 Timeline Planner

After M36.2 validation passes, the planner reuses M36.3 `build_timeline_keyframe_plan` to prove that the generated object plan can move through the generic timeline/keyframe layer.

## Supported Motion

M36.5 supports only:

```text
motion.type = transform_between
```

## Coordinate Convention

- world handedness: right-handed
- world up axis: `+Z`
- request `rotation_euler_degrees`: degrees
- canonical `rotation_euler`: radians
- Euler order: `XYZ`

## Timeline Behavior

The planner creates exactly two transform keyframes:

- `timeline.start_frame`
- `timeline.end_frame`

It does not synthesize intermediate keyframes, sample curves, evaluate easing, or invent motion.

## Transform Field Matching

`motion.start` and `motion.end` must contain the same transform fields. Supported request fields:

- `location`
- `rotation_euler_degrees`
- `scale`

At least one transform field is required. If a field appears only on one side, the planner rejects the request with `transform_field_mismatch`.

## Location Planning

`location` vectors must contain exactly three finite numbers in the range `-1000000..1000000`. Location values are copied into canonical keyframes as `location` and normalized to 9 decimal places.

## Rotation Degree-To-Radian Conversion

Request rotations use:

```text
rotation_euler_degrees
```

Canonical animation plans use:

```text
rotation_euler
```

Conversion:

```text
radians = degrees * pi / 180
```

Values are rounded to 9 decimal places. The planner does not wrap angles, generate quaternions, build matrices, choose shortest paths, or apply Euler continuity fixes.

## Scale Planning

`scale` vectors must contain exactly three finite numbers. Each value must be greater than `0` and no larger than `1000000`. The planner rejects zero and negative scale.

## Visibility Planning

`visibility.enabled: false` creates no visibility track.

`visibility.enabled: true` creates a separate visibility track after the transform track. Visibility interpolation must be `constant`. Visibility values are never placed inside the transform track.

## Canonical Animation Plan

The generated canonical animation plan contains:

- the computed timeline duration
- one object transform track
- an optional object visibility track
- the original scene, output, and safety metadata copied safely

Track order is deterministic:

1. transform track
2. visibility track, when enabled

## Object Planner Output

CLI reports use:

```json
{
  "schema_version": "1.0",
  "report_type": "object_transform_animation_planner",
  "status": "planned",
  "planned": true,
  "request_path": "configs/animation/object-transform.example.yaml",
  "object_plan": {},
  "errors": [],
  "warnings": [],
  "safety_flags": {}
}
```

`object_plan.transform.animated_fields` always uses deterministic order:

```text
location
rotation_euler
scale
```

## Determinism

The request hash uses canonical JSON serialization with sorted keys, compact separators, UTF-8, and `allow_nan=False`. Output contains no timestamp, UUID, mtime, cwd, environment dump, hostname, or absolute host path.

## Mutation Safety

The planner deep-copies request data before producing output and never returns caller-owned request lists or dicts as mutable output.

## CLI

Run:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/object_transform_animation_planner.py \
  --request configs/animation/object-transform.example.yaml \
  --pretty
```

Allowed arguments:

- `--request PATH`
- `--pretty`

## Exit Codes

- `0`: request valid and object plan produced
- `1`: request loaded, but validation or planning failed
- `2`: path, loading, malformed input, schema, or tooling error

## Warnings

If start and end transform values are identical, the planner still creates the two requested keyframes and emits:

```text
object_transform_unchanged
```

## M36.6 Boundary

M36.6 remains the future Blender Animation Adapter Plan. M36.5 does not produce Blender operation plans and does not translate canonical animation plans into `bpy` calls.

## Deferred Features

Deferred features include object path generation, multi-object requests, parent-child transforms, local-space transforms, pivot changes, constraints, collision detection, physics, material animation, shape keys, armature and bone animation, quaternion interpolation, Euler unwrapping, shortest rotation paths, intermediate keyframe synthesis, and runtime object resolution.

## Non-Goals

M36.5 does not implement Blender execution, real keyframe writing, preview rendering, runtime output, Gateway endpoints, Dashboard UI, Docker services, reference-board integration, or M36.6 adapter behavior.

## Test Coverage

Run:

```bash
make test-object-transform-animation-planner
```

The regression covers valid YAML/JSON requests, malformed and invalid inputs, field matching, location/rotation/scale validation, degree-to-radian conversion, visibility track behavior, canonical plan validation, M36.3 timeline integration, request hashing, mutation safety, warnings, safety flags, no Blender/process/runtime behavior, fixture cleanup, and M36.6 non-start.

## Final Decision

M36.5 is DONE when the object planner, schema, example request, docs, review template, layout requirements, roadmap updates, and source-only regressions pass. M36.6 remains planned and unimplemented.
