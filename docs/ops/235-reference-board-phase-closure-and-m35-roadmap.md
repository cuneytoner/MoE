# Reference Board Phase Closure and M35 Roadmap

## Purpose

Close the M34 Reference Board phase and define the next phase boundary.

## M34 Completed Scope

M34 completed the reference board, output review, export, and repair foundation:

- output cards API/UI
- image and drawing preview handling
- metadata sidecars
- reference board API/UI
- item selection and notes/tags edit
- JSON and Markdown exports
- downloads
- export regression
- export polish
- validation limits
- malformed store regression
- validate CLI
- backup CLI
- repair-schema CLI
- duplicate item repair
- stale item marking
- repair regressions
- operator runbook
- summary review
- backup retention plan
- export review status
- dashboard export review UI polish

## Safety Boundaries Preserved

- Generated media stayed out of source control.
- Runtime files stayed under `/home/cuneyt/MoE/runtime`.
- Models stayed outside the repo.
- Dashboard repair/apply controls were not added.
- Arbitrary shell execution was not added.
- Source asset deletion was not added.
- Metadata sidecar deletion was not added.
- Reference board tools did not trigger generation.
- `APPLY=1` remains explicit for repair paths.

## M34 Closure Decision

- M34 is closed after M34.54.
- New reference board polish should go to backlog unless critical.
- No more M34.x feature expansion by default.
- Future work should start under M35 or a later phase.

## Backlog Moved Out of M34

These items are backlog, not active M34 milestones:

- backup retention CLI implementation
- restore workflow
- stale marker cleanup
- stale item removal plan
- dashboard repair controls, if ever considered
- export PDF/ZIP packaging
- additional compare view polish
- backup cleanup UI, if ever considered

## Recommended M35 Direction

M35.0 starts the next phase.

M35.1 should begin one of these:

- 3D / Blender Parametric Pipeline Foundation
- Rigging Pipeline Foundation
- Dashboard Guarded Actions Plan
- Reference Board Maintenance Backlog Plan

Preferred path:

- M35.1 3D / Blender Parametric Pipeline Foundation

Reason:

Reference boards now provide reviewable visual/source context, so the next value is deterministic 3D/Blender generation from measured specs and selected references.

## M35 Proposed Roadmap

- M35.0 Reference Board Phase Closure and M35 Roadmap
- M35.1 3D / Blender Parametric Pipeline Foundation
- M35.2 Pergola Parametric Blender Prototype Plan
- M35.3 Blender Runtime Output Safety Plan
- M35.4 First Parametric Blender Script Skeleton
- M35.5 3D Export Format Plan
- M35.6 3D Dashboard Output Cards Plan

## Stop Conditions

Do not continue adding M34 work unless:

- regression breaks
- export data becomes unsafe
- repair tool safety regression appears
- repo/runtime separation is violated

## Non-Goals

- no code changes
- no runtime mutation
- no source asset mutation
- no generated media
- no PDF/ZIP
- no new repair behavior
- no dashboard actions
