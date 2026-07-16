# 3D Metadata Sidecar Validator

## What Was Implemented

M35.12 adds a source-only validator for future 3D metadata sidecars.

The validator reads metadata JSON from `/tmp`, checks required fields and safe runtime-relative output file references, and prints a JSON validation report.

It does not run Blender, generate assets, or inspect output file paths on disk.

## Validator CLI

Use `--validate-metadata` with a temporary sidecar path:

```bash
python3 apps/3d-generator/generic_parametric_blender.py \
  --validate-metadata /tmp/example-3d-sidecar.json
```

In this milestone, validation is limited to `/tmp` files.

## Validation Report Shape

The validator prints:

```json
{
  "schema_version": "1.0",
  "report_type": "3d_metadata_sidecar_validation",
  "metadata_path": "/tmp/example-3d-sidecar.json",
  "valid": true,
  "error_count": 0,
  "errors": [],
  "safety_flags": {
    "read_only": true,
    "runtime_assets_written": false,
    "source_assets_modified": false,
    "generation_triggered": false,
    "blender_execution_attempted": false
  }
}
```

The command exits `0` when valid and non-zero when invalid.

## Required Fields

The validator checks:

- `schema_version`
- `asset_type`
- `source`
- `generator_script`
- `generator_version`
- `project_name`
- `asset_name`
- `asset_category`
- `config_hash`
- `units`
- `coordinate_system`
- `component_count`
- `component_types`
- `output_files`
- `created_at`
- `safety_label`
- `structural_certification`
- `operator_review_required`
- `safety_flags`

## Output Path Safety

`output_files` values must be either `null` or safe runtime-relative strings.

The validator rejects:

- absolute paths
- path traversal
- repo-looking paths
- model backup-looking paths

The validator does not access the filesystem for `output_files`.

## /tmp-Only Validation Boundary

M35.12 only validates metadata files under `/tmp`.

Repo paths and runtime paths are rejected in this milestone to avoid accidental runtime sidecar use before the runtime asset flow is implemented.

## Read-Only Behavior

Validation is pure and read-only.

Safety flags in the report always keep:

- `read_only` true
- `runtime_assets_written` false
- `source_assets_modified` false
- `generation_triggered` false
- `blender_execution_attempted` false

## Negative Tests

The regression test verifies:

- invalid `asset_type` is rejected
- unsafe `safety_label` is rejected
- `structural_certification: true` is rejected
- absolute `output_files` values are rejected
- repo validation paths are rejected
- runtime validation paths are rejected

## No Runtime Assets

M35.12 does not create `.blend`, `.glb`, `.obj`, `.fbx`, `.mtl`, image, video, render, report, preview, or runtime metadata files.

## No Blender Execution

The validator uses normal Python only.

It does not import `bpy`, run Blender, or call any generation path.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-metadata-sidecar-validator
```

Expected:

- valid temporary sidecar validates successfully
- invalid temporary sidecar fails with a JSON report
- repo path validation is rejected
- runtime path validation is rejected
- no generated 3D files appear in the repo

## Fixed Roadmap

Next milestone: M35.13 Generic Primitive Builder Core.

- M35.13 Generic Primitive Builder Core
- M35.14 Blender Adapter Implementation
- M35.15 First Guarded Local Blender Generation Drill
- M35.16 Generated 3D Artifact Verification
- M35.17 3D Output Card API
- M35.18 Dashboard 3D Output Cards UI
- M35.19 3D Reference Board Selection
- M35.20 M35 Phase Closure
