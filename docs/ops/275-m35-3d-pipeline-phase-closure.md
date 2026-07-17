# M35 3D Pipeline Phase Closure

## Purpose

M35 closes the generic 3D / Blender parametric pipeline foundation. This closure documents what was delivered, what safety boundaries are now enforced, what tests cover the phase, and what remains deferred.

M35 is closed as a source/runtime/model separation milestone. It does not start M36 implementation.

## Completed Milestone Map

| Milestone | Title | Status | Primary deliverable | Primary safety boundary |
| --- | --- | --- | --- | --- |
| M35.1 | 3D / Blender Parametric Pipeline Foundation | DONE | Foundation and scope docs | No Blender execution or asset generation |
| M35.2 | Generic Parametric Blender Prototype Plan | DONE | Prototype architecture plan | Planning only, no generated assets |
| M35.3 | Blender Runtime Output Safety Plan | DONE | Runtime output safety rules | 3D binaries stay under runtime |
| M35.4 | Generic Parametric Blender Script Skeleton | DONE | Dry-run script skeleton | No module-level `bpy` import |
| M35.5 | Generic 3D Parameter Config Draft | DONE | Source-only config example | Config validation without generation |
| M35.6 | First Dry-Run Blender Script Review | DONE | Dry-run review and regressions | No runtime mutation |
| M35.7 | Guarded First Blender Generation Drill Plan | DONE | Operator drill plan | Real generation remains off |
| M35.8 | 3D Metadata Sidecar Plan | DONE | Sidecar schema plan | Metadata must be safe and reviewable |
| M35.9 | 3D Output Cards Plan | DONE | Read-only card plan | Discovery only, no runtime writes |
| M35.10 | Guarded Blender Generation Implementation | DONE | Guarded execution path | Requires `REAL_3D_GENERATION=1` and `--execute-generation` |
| M35.11 | 3D Metadata Sidecar Writer | DONE | Metadata writer function | Writer is guarded and tested in temp files |
| M35.12 | 3D Metadata Sidecar Validator | DONE | Sidecar validator | Rejects unsafe paths and model/repo paths |
| M35.13 | Generic Primitive Builder Core | DONE | Scene plan primitives | Blender-independent tests |
| M35.14 | Blender Adapter Implementation | DONE | Blender operation plan adapter | Adapter is importable without Blender |
| M35.15 | First Guarded Local Blender Generation Drill | DONE | Operator command plan | No test-time generation |
| M35.16 | Generated 3D Artifact Verification | DONE | Read-only artifact verifier | Verifies runtime artifacts without creating assets |
| M35.17 | 3D Output Card API | DONE | `GET /gateway/media/3d/cards` | Runtime-scoped, read-only discovery |
| M35.18 | Dashboard 3D Output Cards UI | DONE | Dashboard card panel | No generation or filesystem control UI |
| M35.19 | 3D Reference Board Selection | DONE | `POST /gateway/media/reference-boards/{board_id}/items/3d` | Writes metadata references only |
| M35.20 | M35 Phase Closure | DONE | Closure docs and audit script | No new runtime behavior |

## Architecture Delivered

M35 delivered this pipeline:

```text
parameter config
-> config validation
-> primitive scene plan
-> Blender operation plan
-> guarded Blender execution path
-> runtime outputs
-> metadata sidecar
-> metadata validation
-> artifact verification
-> 3D Output Card API
-> Dashboard cards
-> reference-board metadata selection
```

The layers are intentionally separated:

- Plan/dry-run layer: config loading, scene planning, and operation planning are inspectable without Blender.
- Guarded real-generation layer: execution requires both `REAL_3D_GENERATION=1` and `--execute-generation`.
- Runtime output layer: generated 3D assets belong under `/home/cuneyt/MoE/runtime/media/outputs/3d`.
- Verification layer: sidecar validation and artifact verification are read-only checks.
- Read-only discovery/UI layer: Gateway and Dashboard surface cards without arbitrary browsing or generation.
- Reference metadata write layer: reference-board selection writes only board JSON metadata references.

## Safety Model

M35 keeps default real generation off. The guarded execution path requires two independent operator signals:

```text
REAL_3D_GENERATION=1
--execute-generation
```

The 3D generator and Blender adapter do not import `bpy` at module import time. `bpy` is imported only inside guarded Blender execution paths.

Generated 3D binaries are not written into the source checkout. Model files remain under `/home/cuneyt/MoE_Models_Backup`. Runtime outputs remain under `/home/cuneyt/MoE/runtime`.

Gateway does not expose arbitrary filesystem browsing for 3D cards. Dashboard does not expose generation, delete, repair, cleanup, shell, Docker, or filesystem controls. Reference-board selection writes only metadata references and does not copy, move, delete, rename, repair, or modify 3D assets.

The deployed Dashboard runtime root is `/home/cuneyt/MoE/codebase`; the authoring checkout is not used as a runtime root by default.

## Source/Runtime/Model Separation

- Source: `/home/cuneyt/DiskD/Projects/MoE/codebase`
- Deployed checkout: `/home/cuneyt/MoE/codebase`
- Runtime: `/home/cuneyt/MoE/runtime`
- 3D runtime outputs: `/home/cuneyt/MoE/runtime/media/outputs/3d`
- Models: `/home/cuneyt/MoE_Models_Backup`

The source repo must not contain `node_modules`, `dist`, `build`, `.cache`, `__pycache__`, generated media, model files, logs, or 3D binary artifacts.

## Generation Guard Model

`apps/3d-generator/generic_parametric_blender.py` keeps dry-run behavior as the default. It reports operator commands for reviewed generation, but tests do not run Blender. Guard tests confirm that `--execute-generation` is rejected unless `REAL_3D_GENERATION=1` is also set.

## Metadata And Validation

The metadata sidecar plan, writer, and validator define a safe review surface for generated 3D assets. Validation rejects absolute output paths, traversal, repo paths, runtime paths where unsafe, model backup-looking paths, and unsafe output references.

## Artifact Verification

The artifact verifier reads metadata sidecars and checks declared runtime artifacts without creating or modifying assets. It is suitable for post-generation review after an operator-run drill.

## Gateway API

M35 delivered:

```text
GET /gateway/media/3d/cards
POST /gateway/media/reference-boards/{board_id}/items/3d
```

The 3D cards API scans allowlisted runtime metadata only and returns runtime-relative paths. The reference-board endpoint resolves 3D cards server-side and rejects client-supplied path/name/type/safety fields through strict request validation.

## Dashboard UI

The Dashboard shows read-only 3D cards with placeholder previews, safety labels, verification summary, formats, and metadata path. It can add a 3D card to an active reference board as metadata only. It does not request SVG/3D previews, launch Blender, download assets, or control runtime services.

## Reference Board Selection

3D selection stores `asset_type=3d_model`, a safe card id, a runtime-relative reference path, a metadata path, selected reason, tags, safety label, and timestamp. The selected path is chosen server-side with this priority:

1. verified `glb`
2. verified `blend`
3. verified `obj`
4. metadata fallback

## Test Coverage

M35 regression coverage includes:

- `make test-3d-metadata-sidecar-validator`
- `make test-3d-primitive-builder`
- `make test-3d-blender-adapter`
- `make test-3d-generation-guards`
- `make test-3d-artifact-verifier`
- `make test-3d-output-card-api`
- `make test-3d-reference-board-selection`
- `make test-dashboard-ui`
- `make test-m35-phase-closure`
- reference-board store validation and repair regressions

## Operator-Only Test Evidence

M35.19 accepted operator-provided host evidence:

```text
ALLOW_UI_TEST_NETWORK=1 make test-3d-output-cards-ui
Vite build passed
```

This was treated as operator-provided host evidence because Docker image and network visibility are host-only concerns.

## Known Limitations

- 3D preview serving is not implemented.
- The Dashboard uses placeholder 3D previews.
- Real operator generation evidence remains a future post-guarded-generation review item.
- Primitive coverage is intentionally basic.
- Material, lighting, camera preset, animation, and rigging depth are deferred.
- Large Dashboard bundle/code-splitting remains a future UI performance topic.

## Backlog After M35

| Title | Reason deferred | Safety consideration | Suggested future milestone |
| --- | --- | --- | --- |
| 3D preview serving | M35 cards intentionally use placeholders | Preview serving must stay card-id based and avoid arbitrary paths | M36+ media review polish |
| Real operator generation drill evidence | M35 focused on foundations and guards | Operator-run generation must stay explicit and runtime-only | Future guarded 3D drill review |
| Additional primitive types | Current builder proves the core shape | New primitives must remain deterministic and Blender-independent in tests | Future 3D primitive expansion |
| Materials, lighting, and camera presets | Operation planning exists but visual polish is deferred | Must not weaken generation guards or source/runtime separation | Future 3D quality milestone |
| 3D compare/review polish | Reference selection is metadata-only | UI must remain free of asset mutation controls | Future dashboard review milestone |
| Artifact retention and cleanup policy | Cleanup was out of M35 closure scope | No automatic deletion without reviewed policy | Future runtime retention milestone |
| Reference-board stale 3D item review | Stale handling exists for boards but 3D-specific review can improve | Must not delete source/runtime assets automatically | Future reference-board hardening |
| Animation and rigging | Explicitly outside M35 | M36 must start as planning/guarded foundation, not uncontrolled rendering | M36.0+ |

## Next Phase Recommendation

The next planned milestone is:

```text
M36.0 Animation Pipeline
```

M36 should start with planning, safety boundaries, and dry-run/keyframe representations before any Blender animation execution.

## Final Closure Decision

M35.20 is DONE.

M35 phase is CLOSED.

Next planned milestone: M36.0 Animation Pipeline.
