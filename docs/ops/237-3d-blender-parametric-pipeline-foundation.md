# 3D / Blender Parametric Pipeline Foundation

## Purpose

Define the safe foundation for deterministic Blender-based 3D generation.

## Phase Boundary

- M34 reference board phase is closed.
- M35 starts 3D / Blender parametric pipeline work.
- M35.2 defines the generic parametric Blender prototype plan and keeps project-specific examples separate from the core architecture.
- M35.3 defines runtime output safety before any Blender execution.
- This milestone does not generate 3D assets.
- This milestone does not run Blender.

## Design Goals

- deterministic geometry first
- parametric dimensions
- source-only scripts
- generated 3D outputs under runtime
- no generated binary assets in git
- manual operator review before real generation
- begin with simple structures before complex rigging/animation
- preserve AI-generated images as visual references only, not engineering truth

## Proposed Runtime Layout

Plan generated outputs under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Suggested subfolders:

- blender
- glb
- obj
- previews
- reports
- metadata

Do not create these folders in this milestone unless existing repo conventions require runtime prep docs only.

## Proposed Source Layout

Plan source-only future structure:

```text
apps/3d-generator/
packages/geometry/
configs/3d/
scripts/
```

Do not add heavy implementation yet unless minimal placeholder files are needed by repo style.

## Parametric Object Model

Plan basic entities:

- scene
- units
- coordinate system
- material labels
- posts
- beams
- rafters
- roof sheets
- panels
- connectors/placeholders
- annotations/placeholders

## Pergola Case Study

Use the existing pergola as first test object later:

- width/depth/height parameters
- post grid
- sloped roof plane
- optional side panel
- roof sheet placeholders
- no structural certification
- mark output as visual/technical reference only

## Blender Execution Safety

Plan:

- no Blender execution from Gateway
- no Dashboard shell execution
- no automatic generation
- future generation requires explicit operator command
- future `APPLY=1`-style guard if scripts can create runtime assets
- runtime outputs only
- source repo remains binary-clean

## Metadata Sidecars

Plan sidecar metadata for future 3D outputs:

- `schema_version`
- `asset_type`: `3d_model`
- `source`: `blender_parametric`
- `generator_script`
- `parameters`
- `units`
- `created_at`
- `output_files`
- `safety_label`: `visual_reference_only`
- `notes`

## Export Format Plan

Future formats:

- `.blend` for Blender source scene
- `.glb` for web/dashboard preview
- `.obj` for simple interchange
- optional preview PNG later

For now:

- no exports generated in M35.1

## Dashboard Integration Later

Plan read-only dashboard cards later:

- model name
- format
- dimensions
- preview placeholder
- metadata summary
- open/download only if explicitly implemented later
- no generate button

## Safety Boundaries

- no generated binaries in repo
- no model files in repo
- no runtime mutation in this milestone
- no shell execution through apps
- no source asset deletion
- no generation
- no PDF/ZIP
- no Blender install/run

## Future Milestones

- M35.2 Generic Parametric Blender Prototype Plan
- M35.3 Blender Runtime Output Safety Plan
- M35.4 Generic Parametric Blender Script Skeleton
- M35.5 Generic 3D Parameter Config Draft
- M35.6 First Dry-Run Blender Script Review
