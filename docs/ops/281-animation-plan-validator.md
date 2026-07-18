# Animation Plan Validator

## Purpose

M36.2 adds a source-only, read-only validator for animation plans. It loads the canonical schema, safely loads YAML or JSON animation plans, checks structural rules, checks timeline/keyframe semantics, and emits deterministic machine-readable validation reports.

It does not write keyframes, resolve runtime assets, import Blender, render previews, start external processes, expose Gateway endpoints, or change Dashboard UI. M36.3 reuses this validator before building Blender-independent timeline/keyframe plans.

## Validator Location

Validator source:

```text
apps/media-worker/app/animation_plan_validator.py
```

Regression script:

```text
scripts/test-animation-plan-validator.sh
```

Make target:

```bash
make test-animation-plan-validator
```

## Canonical Schema

The validator always loads the fixed source schema:

```text
configs/animation/animation-plan.schema.json
```

The schema path is not accepted from CLI arguments. This avoids arbitrary schema loading and keeps the contract pinned to the reviewed M36.1 artifact.

## Supported Input Formats

Supported plan extensions:

- `.yaml`
- `.yml`
- `.json`

YAML is loaded with `yaml.safe_load`. JSON is loaded with the Python standard library JSON parser.

## Input Path Safety

Only these input locations are accepted:

- `configs/animation/*.yaml`
- `configs/animation/*.yml`
- `configs/animation/*.json`
- `/tmp/*.yaml`
- `/tmp/*.yml`
- `/tmp/*.json`

Input files must be regular files, must not be symlinks, must not use traversal, and must be no larger than 256 KiB.

The validator does not read animation plans from runtime, model backup, arbitrary source folders, deployed checkouts, or operator-selected schema paths.

Reports sanitize paths. Source config plans are reported as source-relative paths, and `/tmp` fixtures are reported as `/tmp/<filename>`.

## Structural Validation

Structural validation follows the M36.1 schema contract and checks:

- root object
- unknown top-level fields
- required top-level fields
- `schema_version == "1.0"`
- `mode == "dry_run"`
- safety constants
- strict timeline object
- strict scene object
- strict `source_scene` object
- strict track objects
- strict keyframe objects
- strict outputs
- strict safety object
- plan id and track id pattern
- target, property, and interpolation allowlists
- fps bounds
- track count bounds
- keyframe count bounds
- vector length and finite numeric values
- `outputs.preview.enabled == false`
- `safety.runtime_write_planned == false`
- output path patterns

Boolean values are rejected for integer and number fields. NaN and infinity are rejected.

## Semantic Validation

Semantic validation starts only after the structural checks pass. It covers deterministic timeline and keyframe relationships, not runtime scene resolution.

## Timeline Duration Rule

Frame range must satisfy:

```text
end_frame > start_frame
```

Expected duration is:

```text
(end_frame - start_frame + 1) / fps
```

Allowed tolerance is:

```text
max(0.001, 0.5 / fps)
```

Plans outside that tolerance fail with:

```text
timeline_duration_mismatch
```

## Track Uniqueness

Every `track_id` must be unique within the plan.

Duplicate tracks fail with:

```text
duplicate_track_id
```

## Keyframe Ordering

For each track:

- keyframe frames must stay inside the timeline range
- duplicate keyframe frames are rejected
- keyframe frames must be strictly increasing

The relevant error codes are:

- `keyframe_outside_timeline`
- `duplicate_keyframe_frame`
- `keyframes_not_strictly_increasing`

## Property Compatibility

Track property compatibility is validated per keyframe:

- `transform` requires at least one of `location`, `rotation_euler`, or `scale`
- `transform` must not contain `visibility`
- `location` requires only `location`
- `rotation_euler` requires only `rotation_euler`
- `scale` requires only `scale`
- `visibility` requires only `visibility`

Property mismatch errors use:

```text
keyframe_property_mismatch
```

Camera-specific and object-specific behavior remains deferred to future planner milestones.

## Identifier Safety

The validator checks safe identifiers for:

- `plan_id`
- `track_id`
- `scene.source_scene.reference_id`
- `track.target_id`

Identifiers must not contain path separators, traversal, leading dots, absolute paths, drive prefixes, UNC prefixes, URL schemes, runtime host path markers, repo path markers, or model backup markers.

`reference_id` and `target_id` are stable identifiers, not filesystem paths.

## Output Path Safety

Preview paths must follow:

```text
media/animation/previews/<safe-name>.<format>
```

Metadata paths must follow:

```text
media/animation/metadata/<safe-name>.json
```

The validator rejects leading slashes, backslashes, empty segments, `.` and `..` segments, URLs, drive prefixes, host path markers, repo paths, model backup markers, and normalized-path changes.

Preview extension must match `outputs.preview.format`.

## Validation Report

The validator prints JSON to stdout. The report shape is stable:

```json
{
  "schema_version": "1.0",
  "report_type": "animation_plan_validation",
  "plan_path": "configs/animation/animation-plan.example.yaml",
  "valid": true,
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "summary": {
    "plan_id": "camera-orbit-demo",
    "fps": 24,
    "start_frame": 1,
    "end_frame": 120,
    "duration_seconds": 5,
    "track_count": 1,
    "keyframe_count": 2,
    "target_types": ["camera"],
    "properties": ["transform"],
    "interpolations": ["bezier"]
  },
  "safety_flags": {
    "read_only": true,
    "runtime_assets_written": false,
    "source_assets_modified": false,
    "generation_triggered": false,
    "blender_execution_attempted": false,
    "preview_render_attempted": false,
    "external_process_started": false
  }
}
```

Invalid reports keep the same shape. Reports must not include tracebacks, exception reprs, absolute repo paths, runtime roots, model paths, or environment dumps.

## Exit Codes

- `0`: plan is valid
- `1`: plan loaded, but validation failed
- `2`: path, loading, malformed input, schema, or tooling error

Malformed YAML and malformed JSON return exit code `2`.

## Runtime Reference Resolution Deferral

M36.2 intentionally does not resolve stable ids into runtime files. Future guarded preflight work should handle:

- stable id resolution
- runtime asset existence
- allowlisted runtime root resolution
- symlink checks
- Blender target existence

This keeps M36.2 independent from runtime state and keeps default tests source-only.

## Source/Runtime/Model Boundaries

The validator reads only the canonical source schema and an allowlisted source or `/tmp` input plan. It does not write runtime files, source assets, generated media, preview videos, rendered frames, model files, logs, caches, or reports on disk.

## Non-Goals

M36.2 does not implement:

- M36.4 camera planner
- M36.5 object transform planner
- request normalization
- runtime asset existence checks
- runtime symlink resolution
- Blender adapter work
- `bpy` import
- keyframe writing
- preview rendering
- ffmpeg
- Gateway endpoints
- Dashboard changes
- reference-board integration
- Docker service changes

## Test Coverage

Run:

```bash
make test-animation-plan-validator
```

The regression covers valid YAML and JSON, malformed inputs, path restrictions, structural errors, semantic errors, property compatibility, identifier safety, output path safety, deterministic reports, safety flags, runtime write audit, Blender import audit, external execution audit, and planner-boundary safety.

## Final Decision

M36.2 is DONE as the source-only validator milestone. M36.3 adds the Blender-independent timeline/keyframe planner core, while camera/object planner behavior and runtime preflight checks remain deferred.
