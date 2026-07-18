# Animation Plan Schema

## Purpose

M36.1 defines the canonical source-only contract for animation plans. It turns the M36.0 example shape into a strict JSON Schema without adding Blender execution, preview rendering, Gateway endpoint, Dashboard UI, or runtime write path.

M36.2 adds the source-only validator that loads this schema, loads YAML/JSON plans from allowlisted paths, checks structural rules, and checks timeline/keyframe semantics. Runtime asset resolution and Blender target checks remain deferred to future guarded preflight work.

## Canonical Schema Location

The canonical schema is:

```text
configs/animation/animation-plan.schema.json
```

The source-only example plan remains:

```text
configs/animation/animation-plan.example.yaml
```

## Schema Versioning

The schema uses JSON Schema Draft 2020-12 and the identity:

```text
urn:moe:animation-plan-schema:1.0
```

The plan-level `schema_version` is fixed to `1.0`. Breaking contract changes require a future explicit milestone and a new compatibility note.

## Top-Level Contract

The top-level object is strict and rejects additional properties. Required fields are:

- `schema_version`
- `plan_id`
- `title`
- `description`
- `mode`
- `visual_reference_only`
- `structural_certification`
- `operator_review_required`
- `timeline`
- `scene`
- `tracks`
- `outputs`
- `safety`

`mode` is currently limited to `dry_run`.

## Timeline Contract

The timeline contract defines:

- `fps`: integer, 1 through 120
- `start_frame`: integer, minimum 0
- `end_frame`: integer, minimum 1
- `duration_seconds`: number greater than 0

Structural validation covers the field types and bounds only.

## Scene Source Contract

Scene source references are intentionally indirect. The current source type allowlist is:

- `existing_runtime_3d_asset`

`reference_id` is a safe reference id, not a filesystem path. It must not be an absolute path, traversal path, URL, repo path, model path, or host-specific location.

## Track Contract

Each track is strict and requires:

- `track_id`
- `target_type`
- `target_id`
- `property`
- `interpolation`
- `keyframes`

The top-level `tracks` array allows 1 through 64 tracks. Each track allows 1 through 1000 keyframes.

## Keyframe Contract

Each keyframe requires `frame` and at least one keyed value:

- `location`
- `rotation_euler`
- `scale`
- `visibility`

Vector values are exactly three numbers. `visibility` is boolean.

## Target Allowlist

Allowed `target_type` values are:

- `camera`
- `object`

## Property Allowlist

Allowed `property` values are:

- `transform`
- `location`
- `rotation_euler`
- `scale`
- `visibility`

## Interpolation Allowlist

Allowed `interpolation` values are:

- `constant`
- `linear`
- `bezier`

## Output Contract

The output contract is declarative only.

Preview output requires:

- `enabled: false`
- `format`: `mp4`, `webm`, or `gif`
- `relative_runtime_path`: a runtime-relative preview path under `media/animation/previews/`

Metadata output requires:

- `relative_runtime_path`: a runtime-relative metadata path under `media/animation/metadata/`

No runtime files are created by M36.1.

## Safety Contract

Safety fields are constants:

- `visual_reference_only: true`
- `structural_certification: false`
- `operator_review_required: true`
- `real_animation_enabled: false`
- `blender_execution_enabled: false`
- `preview_render_enabled: false`
- `source_assets_modified: false`
- `runtime_write_planned: false`

## Runtime-Relative Path Rules

Schema-level structural checks reject absolute paths, traversal, backslashes, URLs, drive prefixes, repo paths, model backup references, and common host path markers for output references.

Runtime-relative paths are plan references only. M36.1 does not resolve symlinks, inspect runtime assets, write metadata, render previews, or create animation binaries.

## Structural Validation

Structural validation covers:

- JSON Schema identity and version
- required fields
- strict additional-property behavior
- types
- enums
- constants
- string lengths
- array bounds
- basic safe-id and runtime-relative path patterns

## Semantic Validation Status

M36.2 implements loading plus structural and timeline/keyframe semantic validation. Future preflight checks still include:

- target resolution
- runtime asset existence
- symlink and filesystem resolution

## Backward Compatibility Policy

Compatible additions may be made only through explicit milestones. Any change that loosens execution, rendering, path, model, source mutation, or runtime write constraints needs a reviewed safety milestone before implementation.

## Non-Goals

M36.1 does not implement:

- YAML or JSON loading
- semantic validation
- animation planning logic
- Blender adapters
- keyframe writing
- rendering
- video encoding
- Gateway endpoints
- Dashboard UI
- runtime output creation

## Test Coverage

Run:

```bash
make test-animation-plan-schema
```

The test checks the schema identity, strictness, safety constants, allowlists, path patterns, example alignment, source/runtime/model boundaries, and absence of animation execution implementation.

## Final Decision

M36.1 is DONE as the canonical schema contract. M36.2 adds the source-only validator for loading, structural validation, and timeline/keyframe semantic validation; runtime reference resolution remains deferred to future guarded preflight work.
