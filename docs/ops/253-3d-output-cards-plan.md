# 3D Output Cards Plan

## Purpose

Plan read-only output cards for future generated 3D assets.

## Scope

- Plan output card discovery.
- Plan metadata summary fields.
- Plan preview behavior.
- Plan Dashboard display boundaries.
- Plan download/open behavior.
- Do not implement Gateway or Dashboard changes in this milestone.
- Do not generate 3D assets.

## Current State

- 3D generator skeleton exists.
- Generic 3D config exists.
- Dry-run review exists.
- Guarded generation drill plan exists.
- 3D metadata sidecar plan exists.
- No generated 3D runtime assets exist yet.
- No 3D output cards exist yet.

## Future Discovery Source

Future 3D output cards should be discovered from metadata sidecars under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d/metadata
```

Sidecars should point to runtime-relative output files:

- `blender/file.blend`
- `glb/file.glb`
- `obj/file.obj`
- `previews/file.png`
- `reports/file.json`

Do not scan arbitrary filesystem paths.

## 3D Output Card Shape

Plan a future card shape:

```json
{
  "id": "3d_model:<metadata_relative_path>",
  "type": "3d_model",
  "asset_name": "...",
  "asset_category": "...",
  "created_at": "...",
  "formats": ["blend", "glb"],
  "preview_available": false,
  "metadata_path": "metadata/file.json",
  "relative_runtime_paths": {
    "blend": "blender/file.blend",
    "glb": "glb/file.glb",
    "obj": null,
    "preview": null
  },
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "needs_review": true
}
```

## Metadata Summary Fields

Future cards should display:

- `asset_name`
- `asset_category`
- `created_at`
- formats available
- `component_count`
- `component_types`
- dimensions/config summary if safe
- `safety_label`
- `structural_certification`
- `operator_review_required`
- `generation_mode`

## Preview Behavior

- If preview PNG exists later, show preview.
- If GLB viewer is implemented later, it must be read-only.
- If no preview exists, show a placeholder.
- Do not render previews on demand in Dashboard.
- Do not run Blender from preview requests.
- Do not execute shell commands to generate previews.

## Download/Open Behavior

Future allowed read-only actions:

- download generated runtime asset if endpoint explicitly supports it
- download metadata sidecar
- open metadata detail panel
- open preview if safe

Future disallowed actions:

- generate
- regenerate
- delete
- cleanup
- repair
- move
- rename
- shell execution
- arbitrary filesystem browse

## Gateway Boundary

Plan future Gateway endpoints only as read-only:

- list 3D output cards
- read 3D metadata by card id
- optionally download runtime asset by safe card id and format

No generation endpoints in this plan.

## Dashboard Boundary

Plan future Dashboard UI:

- 3D output card list
- metadata drawer
- format badges
- safety badge
- preview placeholder
- no generate button
- no delete button
- no shell button
- no cleanup button

## Path Safety

Future card resolver must:

- resolve only under `/home/cuneyt/MoE/runtime/media/outputs/3d`
- reject absolute paths from sidecars unless explicitly operator-local and not exposed
- reject path traversal
- reject symlinks for downloadable assets
- reject repo paths
- reject model backup paths
- never expose arbitrary filesystem listings

## Relationship to Reference Boards

- future 3D cards may be selectable into reference boards only after a separate reviewed milestone.
- 3D assets should remain `visual_reference_only` unless policy changes.
- Reference boards must not mutate source 3D assets.

## Testing Plan

Future tests should verify:

- no generated 3D binaries in repo
- card discovery uses metadata sidecars only
- unsafe paths are rejected
- missing files produce controlled unavailable status
- no generation is triggered by card listing
- no shell execution is available
- dashboard remains read-only

## Non-Goals

- no Gateway implementation
- no Dashboard implementation
- no generation
- no Blender execution
- no runtime mutation
- no generated assets
- no asset download endpoints yet
- no GLB viewer yet
- no ZIP/PDF
- no cleanup/delete controls

## Future Milestones

- M35.10 Guarded Blender Generation Implementation
- M35.11 3D Metadata Sidecar Writer
- M35.12 3D Metadata Sidecar Validator
- M35.13 3D Output Card API Plan
- M35.14 3D Output Card API Implementation
- M35.15 Dashboard 3D Output Card UI Plan
