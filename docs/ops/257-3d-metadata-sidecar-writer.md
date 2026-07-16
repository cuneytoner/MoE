# 3D Metadata Sidecar Writer

## What Was Implemented

M35.11 adds a source-only metadata sidecar writer for future 3D assets.

The writer can:

- build metadata sidecar JSON in memory
- compute a SHA-256 hash for the validated config file
- write metadata JSON atomically to a `/tmp` path for tests

It does not run Blender and does not create runtime 3D assets.

## Metadata Plan JSON Mode

Use `--metadata-plan-json` with `--config` to print the planned sidecar JSON to stdout:

```bash
python3 apps/3d-generator/generic_parametric_blender.py \
  --config configs/3d/generic-object.example.json \
  --metadata-plan-json
```

This mode does not write files.

## Temporary Sidecar Writer Mode

Use `--write-metadata PATH` with `--config` to write a sidecar JSON file.

In M35.11, `PATH` must stay under `/tmp`.

This mode does not require Blender, does not trigger generation, and does not write runtime assets.

## Config Hash Behavior

The writer computes `config_hash` as the SHA-256 hex digest of the config file bytes.

This lets later operators connect a metadata sidecar to the exact source config used to create the plan.

## Atomic Write Behavior

The writer creates the destination parent directory when it is under `/tmp`, writes JSON to a temporary file in the same directory, flushes it, and then replaces the destination path atomically.

Repo paths, runtime paths, path traversal, and symlink destinations are rejected.

## Why Only /tmp Writes Are Allowed

M35.11 is a writer implementation milestone, not a real generation milestone.

Limiting writes to `/tmp` keeps tests source-only and prevents accidental runtime media mutation before generated assets exist.

## Safety Flags

Metadata plan JSON keeps:

- `blender_execution_attempted` false
- `runtime_assets_written` false
- `source_assets_modified` false
- `generation_triggered` false
- `metadata_written` false

Temporary sidecar writes set only:

- `metadata_written` true

They still keep:

- `runtime_assets_written` false
- `generation_triggered` false

## No Runtime Assets

M35.11 does not create `.blend`, `.glb`, `.obj`, `.fbx`, `.mtl`, image, video, render, report, preview, or runtime metadata files.

## No Blender Execution

The metadata writer uses normal Python only.

It does not import `bpy`, run Blender, or call any generation path.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-metadata-sidecar-writer
```

Expected:

- metadata plan JSON is valid
- config hash is present
- `/tmp` metadata write succeeds
- repo path write is rejected
- runtime path write is rejected
- no generated 3D files appear in the repo

## Fixed M35 Roadmap

- M35.12 3D Metadata Sidecar Validator
- M35.13 Generic Primitive Builder Core
- M35.14 Blender Adapter Implementation
- M35.15 First Guarded Local Blender Generation Drill
- M35.16 Generated 3D Artifact Verification
- M35.17 3D Output Card API
- M35.18 Dashboard 3D Output Cards UI
- M35.19 3D Reference Board Selection
- M35.20 M35 Phase Closure
