# Animation Pipeline Foundation

## Purpose

M36.0 starts the Animation Pipeline phase with a source-only foundation and roadmap. It defines how text requests can become deterministic animation/keyframe plans later, without running Blender, adding keyframes, rendering frames, encoding videos, or writing runtime outputs in this milestone.

## Phase Scope

M36 starts from the completed M35 3D foundation. This milestone defines contracts for animation plans, timeline rules, target/property allowlists, runtime output boundaries, metadata sidecars, guard requirements, and the M36 roadmap.

## Non-Goals

- No Blender execution.
- No `bpy` keyframe insertion.
- No frame render.
- No video encode or ffmpeg invocation.
- No runtime output write.
- No Gateway endpoint.
- No Dashboard feature.
- No reference-board integration.
- No preview generation.
- No Docker service change.
- No PC-2 deployment change.
- No model download.
- No animation generation API.

## Existing M35 Foundations Reused

M36 should reuse these M35 patterns:

- Source-only config examples.
- Dry-run-first planning.
- Deterministic primitive and operation-plan thinking.
- Guarded execution with independent operator gates.
- No module-level `bpy` import.
- Runtime-relative output references.
- Metadata sidecar validation.
- Artifact verification before UI/API trust.
- Read-only Gateway/Dashboard discovery boundaries.
- Reference-board metadata-only selection boundaries.

## Animation Request Lifecycle

```text
text request
-> request normalization
-> animation intent classification
-> deterministic timeline plan
-> target resolution
-> keyframe plan
-> Blender operation plan
-> guarded execution
-> runtime frames/video
-> metadata sidecar
-> artifact verification
-> future API/UI discovery
```

| Layer | Input | Output | Allowed side effects | Forbidden side effects | Validation responsibility |
| --- | --- | --- | --- | --- | --- |
| Text request | Operator prompt | Raw intent text | None | Runtime writes, generation | Length and safety review |
| Request normalization | Raw intent text | Structured request fields | None | Path acceptance from prompt | Strip unsafe paths and unsupported controls |
| Intent classification | Structured request | Animation intent | None | Model switching, generation | Allowed intent set |
| Deterministic timeline plan | Intent and constraints | Timeline frames/fps/duration | None | Runtime writes | FPS/frame bounds |
| Target resolution | Plan and source scene reference | Target ids/types | None | Arbitrary filesystem lookup | Allowlisted runtime references only |
| Keyframe plan | Timeline and targets | Track keyframes | None | Blender writes | Target/property/interpolation allowlists |
| Blender operation plan | Keyframe plan | Future Blender operations | None | `bpy` import by default | Operation schema checks |
| Guarded execution | Operation plan plus explicit guards | Runtime frames/video | Runtime-only outputs after approval | Source writes, model writes | `REAL_ANIMATION_GENERATION=1` and `--execute-animation` |
| Runtime frames/video | Guarded execution outputs | Runtime artifacts | Runtime-only files | Git-tracked media | Runtime root/path policy |
| Metadata sidecar | Plan and artifact facts | Runtime metadata JSON | Runtime sidecar after approval | Secrets, shell history, absolute host paths | Sidecar schema validator |
| Artifact verification | Metadata sidecar | Verification report | Read-only report | Asset mutation | Runtime-relative artifact checks |
| Future API/UI discovery | Verified metadata | Cards/review UI | Read-only API/UI | Generation controls | Card-id based discovery |

## Animation Plan Architecture

The source-only example lives at:

```text
configs/animation/animation-plan.example.yaml
```

It is an example contract, not an executor. M36.0 does not add a parser, runtime writer, Blender adapter, renderer, or API.

## Timeline Model

Initial limits:

- `fps`: 1..120
- `start_frame`: >= 0
- `end_frame`: > `start_frame`
- `duration`: derived and finite
- max tracks: 64
- max keyframes per track: 1000
- max plan id length: 80
- max title length: 120
- max description length: 1000

## Target Model

Initial target types:

- `camera`
- `object`

Unsupported targets are deferred to backlog.

## Camera Animation

The first camera animation contract supports transform/location/rotation/scale style keyframes over a bounded timeline. Camera orbit examples should be deterministic and source-only until a later guarded adapter milestone.

## Object Animation

The first object animation contract supports transform-oriented object motion. Object lookup must use future allowlisted scene references, not arbitrary paths from requests.

Initial property values:

- `transform`
- `location`
- `rotation_euler`
- `scale`
- `visibility`

## Interpolation Model

Allowed interpolation values:

- `constant`
- `linear`
- `bezier`

Unsupported animation systems for the foundation:

- armature
- bones
- shape keys
- constraints animation
- materials animation
- physics
- particles
- simulation caches
- audio synchronization
- motion capture
- nonlinear animation editor

## Frame And Time Model

Frame count and duration must be finite and bounded. Duration should be derived from frame range and FPS during validation rather than trusted blindly from free text.

## Runtime Output Layout

Planned layout only. M36.0 does not create these runtime directories.

```text
/home/cuneyt/MoE/runtime/media/animation/
├── plans/
├── metadata/
├── reports/
├── frames/
└── previews/
```

- `plans/`: normalized runtime animation plans
- `metadata/`: animation sidecars
- `reports/`: execution and verification reports
- `frames/`: optional rendered frame sequences
- `previews/`: review-only preview videos

Source repo output writes are forbidden. Output references in metadata must be runtime-relative. Preview files must not be tracked by Git. Cleanup is not automatic. Retention policy is deferred.

## Preview Output Plan

Preview rendering is disabled by default. Future preview rendering must require:

```text
--render-preview
```

alongside the real animation generation guards.

## Metadata Sidecar Plan

Future animation metadata should include:

- `schema_version`
- `animation_id`
- `plan_id`
- `title`
- `created_at`
- `fps`
- `start_frame`
- `end_frame`
- `duration_seconds`
- `track_count`
- `keyframe_count`
- `target_types`
- `interpolation_types`
- `source_scene_reference`
- `output_files`
- `preview_available`
- `generation_mode`
- `operator_review_required`
- `visual_reference_only`
- `structural_certification`
- `source_assets_modified`
- `runtime_assets_written`
- `blender_version`
- `generator_version`
- `validation`
- `warnings`

Metadata must not contain absolute host paths, secrets, environment dumps, shell history, or model paths.

## Validation Boundaries

Validation must reject absolute paths, traversal, source repo paths, model backup paths, arbitrary host paths, unsupported targets, unsupported properties, unsupported interpolation, unbounded timelines, and unsafe output references.

## Generation Guard Model

Future real animation execution must require both:

```text
REAL_ANIMATION_GENERATION=1
--execute-animation
```

Preview rendering must additionally require:

```text
--render-preview
```

Default animation generation is off. Preview render is off. Blender import must not happen at module import time. `bpy` may only be imported inside a future guarded execution function. ffmpeg must not be invoked automatically.

Existing `.blend` or generated assets must not be modified in the source repo. Runtime input assets must be selected by allowlisted runtime references only. Requests must not accept absolute filesystem paths, source repo paths, model backup paths, or arbitrary host paths. Symlink policy should match the hardened M35 runtime scanning policy.

## Gateway And Dashboard Boundaries

M36.0 adds no Gateway endpoint and no Dashboard feature. Gateway must not become an animation execution surface. Dashboard must not become an animation control plane.

## Operator Workflow

The future operator workflow should be:

1. Review text request.
2. Normalize into a source/runtime-safe animation plan.
3. Validate plan.
4. Review dry-run operation plan.
5. Explicitly enable real animation generation only when ready.
6. Store outputs under runtime.
7. Verify metadata and artifacts.
8. Surface verified outputs through future read-only discovery.

## Failure Handling

Failures should be controlled and reviewable: invalid plans should fail before runtime writes, missing runtime references should be warnings/errors, and render failures should produce reports without modifying source or model files.

## Test Strategy

M36.0 adds a source-only test:

```bash
make test-animation-pipeline-foundation
```

It checks the docs, example config, safety flags, roadmap, source-only audits, and that no implementation surface for animation generation was added.

## M36 Roadmap

| Milestone | Title | Status |
| --- | --- | --- |
| M36.0 | Animation Pipeline Foundation and Roadmap | DONE |
| M36.1 | Animation Plan Schema | DONE |
| M36.2 | Animation Plan Validator | DONE |
| M36.3 | Timeline and Keyframe Planner Core | DONE |
| M36.4 | Camera Animation Planner | DONE |
| M36.5 | Object Transform Animation Planner | DONE |
| M36.6 | Blender Animation Adapter Plan | DONE |
| M36.7 | Guarded Blender Animation Implementation | DONE |
| M36.8 | Animation Metadata Sidecar Writer | DONE |
| M36.9 | Animation Metadata Validator | DONE |
| M36.10 | Preview Render Safety Plan | DONE |
| M36.11 | Guarded Preview Render Implementation | DONE |
| M36.12 | Animation Artifact Verifier | DONE |
| M36.13 | Animation Output Card API Plan | DONE |
| M36.14 | Animation Output Card API | DONE |
| M36.15 | Dashboard Animation Cards UI | DONE |
| M36.16 | Animation Reference Board Selection | PLANNED |
| M36.17 | M36 Phase Closure | PLANNED |

## Backlog

- Armature, bones, shape keys, constraints animation, materials animation, physics, particles, simulation caches, audio synchronization, motion capture, and nonlinear animation editor support.
- Preview retention and cleanup policy.
- Animation compare/review UI.
- Runtime performance and render queue management.
- Future media workflow orchestration across image, 3D, animation, and reference boards.

## Final Decision

M36.0 is DONE as a foundation and roadmap milestone.

Current active phase: M36 Animation Pipeline.

Latest completed milestone: M36.13 Animation Output Card API Plan.

Next planned milestone: M36.14 Animation Output Card API.
