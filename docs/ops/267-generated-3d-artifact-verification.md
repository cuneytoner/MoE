# Generated 3D Artifact Verification

M35.16 adds a read-only verifier for future generated 3D runtime artifact sets.

The verifier is for the period after a guarded Blender drill has produced files under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

This milestone does not run Blender, generate assets, create runtime sidecars, or mutate runtime media.

## What Was Implemented

- `apps/3d-generator/artifact_verifier.py`
- `--verify-artifacts PATH` on `apps/3d-generator/generic_parametric_blender.py`
- `--require-existing-artifacts` for post-generation existence checks
- `scripts/test-3d-artifact-verifier.sh`

The verifier reads metadata, inspects `output_files`, and returns a JSON report. It does not write files, create directories, import `bpy`, or trigger generation.

## Artifact Verifier Purpose

The verifier answers these questions before future 3D output cards consume sidecars:

- Are artifact references runtime-relative?
- Are absolute paths rejected?
- Is path traversal rejected?
- Are repo-looking paths rejected?
- Are model backup-looking paths rejected?
- If requested, do referenced files exist under the runtime 3D output root?

## Verification Report Shape

The report has this shape:

```json
{
  "schema_version": "1.0",
  "report_type": "3d_artifact_verification",
  "valid": true,
  "error_count": 0,
  "errors": [],
  "runtime_root": "/home/cuneyt/MoE/runtime/media/outputs/3d",
  "artifact_count": 0,
  "artifacts": [],
  "safety_flags": {
    "read_only": true,
    "runtime_assets_written": false,
    "source_assets_modified": false,
    "generation_triggered": false,
    "blender_execution_attempted": false
  }
}
```

Each artifact entry includes `key`, `relative_path`, `safe_path`, `exists`, and `size_bytes`.

## Safe Runtime-Relative Path Checks

Allowed examples:

```text
blender/file.blend
glb/file.glb
metadata/file.json
reports/file.json
```

Rejected examples:

```text
/etc/passwd
../bad.glb
docs/bad.glb
apps/bad.glb
scripts/bad.glb
configs/bad.glb
/home/cuneyt/MoE_Models_Backup/model.gguf
```

Allowed output keys are `blend`, `glb`, `obj`, `preview`, `metadata`, and `report`.

## require_existing_files Behavior

By default, verification does not require referenced artifact files to exist. This supports dry reviews of metadata before a real guarded generation run.

When `--require-existing-artifacts` is passed, the verifier checks each referenced file under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Missing files make the report invalid. Existing files report `exists=true` and `size_bytes`.

## /tmp-Only CLI Boundary

For M35.16, `--verify-artifacts PATH` only accepts metadata files under `/tmp`.

This keeps tests fixture-only and prevents accidental runtime metadata inspection from becoming a broader filesystem browser. Runtime metadata verification can be opened deliberately in a later milestone.

## Read-Only Behavior

The verifier:

- reads one metadata JSON file
- returns JSON on stdout
- does not create directories
- does not write reports
- does not modify metadata
- does not inspect arbitrary filesystem paths
- does not run Blender
- does not import `bpy`
- does not trigger generation

## Negative Tests

The test script covers:

- missing artifact failure when `--require-existing-artifacts` is enabled
- absolute output path rejection
- path traversal rejection
- repo metadata path rejection
- runtime metadata path rejection for this milestone
- repo scan for accidental `.blend`, `.glb`, `.obj`, `.fbx`, and `.mtl` files

## No Runtime Writes

Tests use `/tmp` fixtures only. They do not create runtime sidecars or runtime 3D assets.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-artifact-verifier
```

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
```

Expected test output:

```text
3D artifact verifier OK
```

## Fixed Roadmap

- M35.16 Generated 3D Artifact Verification DONE
- M35.17 3D Output Card API PLANNED
- M35.18 Dashboard 3D Output Cards UI PLANNED
- M35.19 3D Reference Board Selection PLANNED
- M35.20 M35 Phase Closure PLANNED
