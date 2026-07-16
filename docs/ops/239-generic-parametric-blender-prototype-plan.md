# Generic Parametric Blender Prototype Plan

## Purpose

Plan the first generic deterministic Blender prototype pipeline.

## Scope

- Plan generic parametric model inputs.
- Plan reusable object hierarchy.
- Plan coordinate system.
- Plan generated output locations for future milestones.
- Keep the pipeline reusable for architecture, product, furniture, outdoor structures, and simple mechanical objects.
- Do not run Blender.
- Do not generate 3D assets.

## Phase Boundary

- M35 is a generic 3D / Blender parametric pipeline phase.
- Project-specific examples must not define the core architecture.
- Pergola can be used later as a sample object, but this milestone remains generic.

## Coordinate System

- units: millimeters
- origin: object or scene base reference point
- X axis: width left-to-right
- Y axis: depth back-to-front
- Z axis: height ground/base-to-up
- support for optional local coordinate frames per object
- support for bounding boxes and object transforms

## Generic Parameter Schema

Plan common fields:

- `project_name`
- `asset_name`
- `asset_category`
- `units`
- `coordinate_system`
- `dimensions`
- `components`
- `materials`
- `output_formats`
- `metadata`
- `safety_label`

For dimensions:

- `width_mm`
- `depth_mm`
- `height_mm`
- `thickness_mm`
- `radius_mm` where needed
- `slope_degrees` or `slope_mm` where needed

For components:

- `component_id`
- `component_type`
- `label`
- `position`
- `rotation`
- `dimensions`
- `material_label`
- `metadata`

## Supported First Object Types

Plan generic primitives:

- `rectangular_prism`
- `cylinder`
- `plane`
- `sloped_plane`
- `frame`
- `panel`
- `connector_placeholder`
- `guide_line`
- `label_anchor`

Do not implement them yet.

## Object Hierarchy

Plan Blender collection/object hierarchy:

- Scene root
- Reference planes
- Primary components
- Secondary components
- Connectors/placeholders
- Guide/dimension helpers
- Labels/annotation anchors
- Metadata/custom properties

## Geometry Generation Strategy

M35.4 starts the source-only script skeleton for the generic prototype pipeline.

- deterministic component generation from parameter JSON/YAML
- reusable primitive builders
- no physics/structural solver in early milestones
- no downloaded textures or external assets
- material labels first, real materials later
- geometry validation before output writing

## Category Examples

- outdoor structure
- furniture
- simple product
- room layout
- mechanical placeholder object
- architectural massing model

Pergola can be one later example under outdoor structure.

## Material Labels

Plan source-only material labels:

- `wood_placeholder`
- `metal_placeholder`
- `glass_placeholder`
- `roof_sheet_placeholder`
- `fabric_placeholder`
- `plastic_placeholder`
- `connector_placeholder`
- `guide_placeholder`

No texture files.
No material binaries.
No downloaded assets.

## Metadata Plan

Future sidecar should include:

- `schema_version`
- `asset_type`: `3d_model`
- `project`
- `asset_name`
- `asset_category`
- `generator`: `blender_parametric`
- `generator_script`
- `parameters`
- `units`
- `coordinate_system`
- `object_counts`
- `output_files`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`
- `notes`

## Runtime Output Plan

M35.3 defines runtime output and generation guard safety for future generic prototypes.

Future outputs should go under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Suggested subfolders:

- blender
- glb
- obj
- previews
- metadata
- reports

Do not create them in this milestone.

## Validation Plan

Future validation should check:

- parameters are valid
- required dimensions are positive
- object ids are unique
- component references are valid
- generated files are under runtime only
- no `.blend`/`.glb`/`.obj`/`.fbx` in git
- metadata sidecar exists for generated outputs
- safety_label is present

## Safety Boundaries

- no Blender execution
- no generated assets
- no binary assets in repo
- no texture/model downloads
- no dashboard generation controls
- no shell execution through apps
- no structural certification claims
- outputs are `visual_reference_only` unless a later reviewed milestone changes that

## Future Milestones

- M35.3 Blender Runtime Output Safety Plan
- M35.4 Generic Parametric Blender Script Skeleton
- M35.5 Generic 3D Parameter Config Draft
- M35.6 First Dry-Run Blender Script Review
- M35.7 Guarded First Blender Generation Drill
