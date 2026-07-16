# Guarded First Blender Generation Drill Plan

## Purpose

Plan how the first real Blender generation drill should happen safely in a later milestone.

## Scope

- Plan generation guards.
- Plan operator steps.
- Plan runtime output handling.
- Plan metadata/report requirements.
- Plan cleanup/review steps.
- Do not run Blender in this milestone.
- Do not generate assets in this milestone.

## Current State

- Generic dry-run script exists.
- Generic config example exists.
- Dry-run review test exists.
- `REAL_3D_GENERATION=1` currently does not write assets.
- No Blender execution exists yet.
- No runtime 3D assets are generated yet.

## Required Guard Conditions

Future real generation must require all of:

- explicit operator command
- `REAL_3D_GENERATION=1`
- valid source-only config
- output root under `/home/cuneyt/MoE/runtime/media/outputs/3d`
- dry-run plan reviewed first
- generated filenames planned before write
- metadata sidecar planned before write
- no existing output overwrite unless explicitly allowed
- no dashboard trigger
- no shell execution through Gateway/Dashboard

## Future Operator Drill Sequence

These commands are planned for a later milestone and must not be run now.

1. Dry-run without generation:

```bash
python3 apps/3d-generator/generic_parametric_blender.py --config configs/3d/generic-object.example.json --plan-json
```

2. Review plan JSON:

- `runtime_output_root`
- `config_summary`
- output file names
- metadata plan
- safety flags

3. Future guarded generation command:

```bash
REAL_3D_GENERATION=1 blender --background --python apps/3d-generator/generic_parametric_blender.py -- --config configs/3d/generic-object.example.json
```

This command is planned for a later milestone and must not be run in M35.7.

## Runtime Output Plan

Future drill should write only under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Suggested future drill output group:

- `blender/simple_frame_example-{timestamp}.blend`
- `glb/simple_frame_example-{timestamp}.glb`
- `metadata/simple_frame_example-{timestamp}.json`
- `reports/simple_frame_example-{timestamp}.json`

No output should be written in repo.

## Metadata Requirement

M35.8 defines the sidecar schema required before future guarded generation writes assets.

Future drill metadata must include:

- `schema_version`
- `asset_type`: `3d_model`
- `source`: `blender_parametric`
- `generator_script`
- `generator_version`
- `project_name`
- `asset_name`
- `asset_category`
- `config_path`
- `parameters_hash`
- `units`
- `coordinate_system`
- `created_at`
- `output_files`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`
- `generation_mode`: `guarded`
- `operator_review_required`: `true`

## Report Requirement

Future drill report must include:

- `report_type`: `blender_generation_drill`
- `dry_run_plan_reviewed`
- `real_generation_enabled`
- `blender_execution_attempted`
- `runtime_assets_written`
- `output_root`
- `generated_files`
- `metadata_file`
- `errors`
- `safety_flags`

## Failure Handling Plan

- if Blender missing, fail cleanly
- if `bpy` import fails outside Blender, fail cleanly
- if output root invalid, fail before writing
- if config invalid, fail before writing
- if metadata cannot be written, fail and do not leave partial assets where practical
- if generation partially succeeds, report exact files for operator review

## Cleanup Boundary

No cleanup implementation now.

Future cleanup after drill must:

- be manual or dry-run first
- operate only under runtime 3D output root
- never touch repo
- never touch model backup
- never touch reference board runtime files
- report files before deletion

## Git Safety

Run:

```bash
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth|pdf|dxf|svg|blend|glb|obj|fbx|mtl)$' || true
```

Expected:

```text
No output.
```

Also:

```bash
find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
```

Expected:

```text
No output under repo.
```

## Dashboard Boundary

- no dashboard generation button
- no dashboard shell execution
- no dashboard cleanup/delete action
- dashboard may later show read-only 3D output cards only after output-card planning

## Stop Conditions

Do not proceed to real generation if:

- dry-run plan is not reviewed
- output path is outside runtime
- config validation fails
- generated filenames are unknown
- metadata plan is missing
- script tries to write into repo
- Git safety check finds generated binaries
- operator does not understand planned outputs

## Non-Goals

- no real generation now
- no Blender execution now
- no script implementation changes now unless docs require naming alignment
- no runtime mutation
- no generated assets
- no dashboard controls
- no cleanup implementation
- no source asset mutation
- no ZIP/PDF

## Future Milestones

- M35.8 3D Metadata Sidecar Plan
- M35.9 3D Output Cards Plan
- M35.10 Guarded Blender Generation Implementation
- M35.11 First Local Blender Generation Drill
