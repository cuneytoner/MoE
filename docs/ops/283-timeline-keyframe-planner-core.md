# Timeline Keyframe Planner Core

## Purpose

M36.3 adds the Blender-independent timeline/keyframe planner core. It converts an already validated animation plan into a deterministic timeline/keyframe plan for review and future adapter layers.

The planner does not parse text requests, classify intent, synthesize camera or object motion, evaluate interpolation curves, sample intermediate frames, import Blender, write keyframes, render previews, start external processes, write runtime files, or expose Gateway/Dashboard features.

## Planner Source

Planner source:

```text
apps/media-worker/app/animation_timeline_planner.py
```

Regression script:

```text
scripts/test-animation-timeline-planner.sh
```

Make target:

```bash
make test-animation-timeline-planner
```

## Relationship To Validator

The planner reuses the M36.2 validator from:

```text
apps/media-worker/app/animation_plan_validator.py
```

It does not copy structural or semantic validation rules. Invalid input produces a planner report with validator issue codes and no `timeline_plan`.

## Input Contract

Accepted CLI input is the same safe plan path contract as the validator:

- `configs/animation/*.yaml`
- `configs/animation/*.yml`
- `configs/animation/*.json`
- `/tmp/*.yaml`
- `/tmp/*.yml`
- `/tmp/*.json`

Input must already satisfy the M36.1 schema and M36.2 semantic validation. The planner does not resolve stable ids into runtime files.

## Output Contract

The planner report is JSON on stdout:

```json
{
  "schema_version": "1.0",
  "report_type": "animation_timeline_planner",
  "status": "planned",
  "planned": true,
  "source_plan_path": "configs/animation/animation-plan.example.yaml",
  "timeline_plan": {},
  "errors": [],
  "warnings": [],
  "safety_flags": {}
}
```

The nested `timeline_plan` contains source plan id, canonical source hash, normalized timeline fields, source scene metadata, ordered track plans, summary counts, planned output references, and safety flags.

## Canonical Plan Hash

The planner computes `source_plan_sha256` from the loaded plan payload with deterministic JSON serialization:

```text
sort_keys=True
separators=(",", ":")
ensure_ascii=False
allow_nan=False
```

It does not include timestamps, random ids, file mtimes, absolute paths, current working directory, or environment variables. Equivalent YAML and JSON payloads produce the same hash.

## Timeline Calculations

For a validated timeline:

- `total_frames = end_frame - start_frame + 1`
- `frame_span = end_frame - start_frame`
- `frame_duration_seconds = 1 / fps`
- `frame_span_seconds = frame_span / fps`
- `duration_seconds = total_frames / fps`

The declared input duration is preserved as `declared_duration_seconds` for audit, while planner calculations use the normalized computed duration.

## Frame Time Convention

Keyframe time is:

```text
time_seconds = (frame - start_frame) / fps
```

The start frame therefore has `time_seconds: 0.0`.

## Normalized Progress

Keyframe progress is:

```text
normalized_progress = (frame - start_frame) / (end_frame - start_frame)
```

The start frame is `0.0`; the end frame is `1.0`. Values are not clamped because invalid ranges and out-of-range keyframes are rejected by the validator.

## Keyframe Normalization

For each source keyframe, the planner emits:

- sequence
- frame
- time seconds
- normalized progress
- values

`values` includes only animation fields that exist in the source keyframe:

- `location`
- `rotation_euler`
- `scale`
- `visibility`

Vectors are normalized to float lists. Visibility remains boolean. The planner does not invent missing transform values, default values, coordinate conversions, or degree/radian conversions.

## Segment Planning

Every adjacent keyframe pair becomes one segment. Segment fields include:

- sequence
- start frame
- end frame
- frame delta
- start/end time
- segment duration
- normalized start/end
- interpolation label

Two keyframes produce one segment. Three keyframes produce two segments. One keyframe produces no segments.

The planner carries the interpolation type only. It does not evaluate Bezier handles, easing, linear values, constant values, samples, or intermediate frames.

## Track Ordering

Source track order is preserved. Tracks are not alphabetically sorted because the source order is the operator review order. Each track receives an explicit `sequence`.

Keyframe order is also preserved after validator checks that frames are strictly increasing.

## Determinism

Planner output is deterministic:

- same input produces byte-identical CLI output
- equivalent YAML and JSON payloads produce the same canonical hash
- summary unique lists are sorted
- floats are rounded to 9 decimal places
- negative zero is normalized to `0.0`
- output contains no timestamp, UUID, filesystem metadata, environment dump, or absolute host path

## Mutation Safety

The planner deep-copies the validated input before planning and never returns caller-owned input lists as output structures. Dataclasses are frozen and serialized into normal JSON dict/list output.

## CLI

Run:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_timeline_planner.py \
  --plan configs/animation/animation-plan.example.yaml \
  --pretty
```

Allowed arguments:

- `--plan PATH`
- `--pretty`

No output, write, runtime-root, execute, render, Blender, ffmpeg, or sample-frame arguments exist.

## Exit Codes

- `0`: valid plan and timeline/keyframe plan produced
- `1`: plan loaded, but validation failed
- `2`: path, loading, malformed input, schema, or tooling error

## Safety Flags

Planner safety flags remain false for runtime writes, source mutation, generation, Blender execution, preview rendering, external process starts, interpolation evaluation, and keyframe writing.

## M36.4 And M36.5 Boundaries

M36.4 remains the future camera animation planner milestone. It may plan camera orbit, look-at targets, camera paths, camera-specific constraints, lenses, and camera transform synthesis.

M36.5 remains the future object transform animation planner milestone. It may plan object movement, rotation, scale, visibility behavior, and object-specific constraints.

M36.3 only normalizes validated keyframes already present in the source plan.

## Non-Goals

M36.3 does not implement:

- text request parsing
- request normalization
- animation intent classification
- camera orbit or look-at calculation
- object transform synthesis
- missing keyframe invention
- interpolation curve evaluation
- intermediate frame sampling
- easing calculation
- Blender operation plans
- `bpy` import
- Blender execution
- keyframe writing
- scene or target resolution
- runtime asset existence checks
- runtime output
- preview rendering
- ffmpeg
- Gateway endpoints
- Dashboard changes
- reference-board integration
- Docker service changes

## Test Coverage

Run:

```bash
make test-animation-timeline-planner
```

The regression covers valid YAML/JSON planning, invalid and malformed input exit codes, validator reuse, mutation safety, canonical hash determinism, timeline math, frame time convention, progress calculation, float normalization, track/keyframe order, segment counts, value normalization, safety flags, no timestamp/UUID/path leakage, no Blender import, no external process surface, no runtime writes, no generated media, fixture cleanup, and M36.4 non-start.

## Final Decision

M36.3 is DONE when the planner, CLI, docs, review template, layout requirements, roadmap updates, and source-only regressions pass. M36.4 remains planned and unimplemented.
