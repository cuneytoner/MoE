# Blender Runtime Output Safety Plan

## Purpose

Define safety rules for future Blender-generated 3D outputs.

## Scope

- Plan runtime output locations.
- Plan allowed generated file types.
- Plan metadata sidecar requirements.
- Plan git safety checks.
- Plan generation guards.
- Do not run Blender.
- Do not generate assets.

## Runtime Output Root

M35.5 validates runtime output root in source-only config before any generation exists.

Future Blender outputs must go under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Suggested structure:

- `/home/cuneyt/MoE/runtime/media/outputs/3d/blender`
- `/home/cuneyt/MoE/runtime/media/outputs/3d/glb`
- `/home/cuneyt/MoE/runtime/media/outputs/3d/obj`
- `/home/cuneyt/MoE/runtime/media/outputs/3d/previews`
- `/home/cuneyt/MoE/runtime/media/outputs/3d/metadata`
- `/home/cuneyt/MoE/runtime/media/outputs/3d/reports`

Do not create these folders in this milestone.

## Source Repo Boundary

- repo stores source code, docs, configs, and tests only
- repo must not store generated 3D assets
- repo must not store Blender binary files
- repo must not store generated previews
- repo must not store downloaded textures/assets

## Generated File Types

Future generated files may include:

- `.blend`
- `.glb`
- `.obj`
- `.mtl`
- `.png` preview
- `.json` metadata sidecar
- `.json` report

Rules:

- `.blend`/`.glb`/`.obj`/`.fbx` generated outputs must stay under runtime
- preview images must stay under runtime
- only source templates/configs may be tracked in git
- metadata examples may be tracked only if they are tiny docs fixtures and not runtime outputs

## Metadata Sidecar Requirement

Every future generated 3D asset should have a metadata sidecar.

Required fields:

- `schema_version`
- `asset_type`: `3d_model`
- `source`: `blender_parametric`
- `generator_script`
- `generator_version`
- `project`
- `asset_name`
- `asset_category`
- `parameters`
- `units`
- `coordinate_system`
- `created_at`
- `output_files`
- `safety_label`: `visual_reference_only`
- `structural_certification`: `false`
- `generation_mode`
- `notes`

## Generation Guard Plan

M35.4 adds a dry-run-only script skeleton and does not generate assets.
M35.6 validates dry-run safety flags before any guarded generation milestone.

Future generation commands should default to dry-run or plan mode.

Plan:

- `REAL_3D_GENERATION=0` by default
- generation scripts should print planned outputs before writing
- writing runtime assets requires explicit `REAL_3D_GENERATION=1`
- scripts must refuse to write outside runtime output root
- scripts must not overwrite existing files unless explicitly allowed
- scripts should create metadata and report files atomically where practical

## Path Safety Rules

Future scripts must:

- resolve output paths
- reject path traversal
- reject absolute output paths supplied by user input
- reject symlinks for output targets
- never write into repo directories
- never write into model backup directories
- never write into arbitrary filesystem paths
- create only expected output filenames

## Git Safety Checks

Run:

```bash
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth|pdf|dxf|svg|blend|glb|obj|fbx|mtl)$' || true
```

Expected:

```text
No output.
```

Also plan future untracked check:

```bash
find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
```

Expected:

```text
No generated files under repo.
```

## Dashboard Boundary

Future dashboard should be read-only unless a later guarded milestone explicitly changes it.

Allowed later:

- list 3D output cards
- show metadata
- show preview placeholder
- download generated runtime asset if explicitly implemented

Not allowed by default:

- generate button
- shell execution
- arbitrary filesystem browsing
- repair/delete controls
- source asset mutation

## Cleanup Boundary

No cleanup implementation in this milestone.

Future cleanup must:

- dry-run first
- operate only under runtime 3D output root
- never delete source files
- never delete model files
- never delete reference board files
- report proposed deletions before apply

## Validation Plan

Future tests should verify:

- no generated 3D assets in repo
- scripts default to dry-run
- output paths are under runtime
- metadata sidecar exists
- safety_label is visual_reference_only
- structural_certification is false
- generation is blocked unless explicitly enabled

## Non-Goals

- no Blender script implementation
- no Blender execution
- no asset generation
- no runtime folder creation
- no dashboard generation UI
- no cleanup implementation
- no ZIP/PDF
- no source asset mutation

## Future Milestones

- M35.4 Generic Parametric Blender Script Skeleton
- M35.5 Generic 3D Parameter Config Draft
- M35.6 First Dry-Run Blender Script Review
- M35.7 Guarded First Blender Generation Drill
- M35.8 3D Output Cards Plan
