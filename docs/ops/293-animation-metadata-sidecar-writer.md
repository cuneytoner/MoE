# Animation Metadata Sidecar Writer

## Purpose

M36.8 adds a source-only animation metadata sidecar writer. It converts a valid M36.7 Blender animation adapter request into a deterministic metadata object for review.

## Writer Source

Source:

```text
apps/media-worker/app/animation_metadata_sidecar.py
```

The module runs with normal `python3` and does not import Blender.

## Input Adapter Request

The writer accepts only adapter request JSON files from:

- `configs/animation/*.json`
- `/tmp/*.json`

Input files must be regular `.json` files, smaller than 512 KiB, non-symlinks, and free of traversal.

## Validation Reuse

The writer reuses M36.7:

- `load_adapter_request(...)`
- `validate_adapter_request(...)`
- `build_blender_animation_operation_plan(...)`

That means M36.2 canonical validation and M36.3 timeline/hash validation remain centralized in the adapter chain.

## Metadata Contract

The metadata object uses:

- `schema_version = "1.0"`
- `metadata_type = "animation_sidecar"`
- `asset_type = "animation"`
- `source = "blender_animation_adapter"`
- `generator_script = "apps/media-worker/app/animation_metadata_sidecar.py"`
- `generator_version = "0.1.0"`
- `generation_mode = "metadata_only"`
- `preview_available = false`

The writer does not accept a separate client-provided animation id or title. Those values come from the canonical animation plan.

## Hash Fields

Hashes are canonical JSON SHA-256 values using sorted keys and compact separators.

The writer records:

- `source_request_sha256`
- `adapter_request_sha256`
- `canonical_plan_sha256`
- `operation_plan_sha256`

Metadata is not produced when the canonical plan hash and timeline plan hash disagree.

## Timeline Summary

Timeline summary includes:

- `fps`
- `start_frame`
- `end_frame`
- `total_frames`
- `duration_seconds`

The writer cross-checks canonical timeline values against the normalized M36.3 timeline plan.

## Animation Summary

Animation summary includes track, keyframe, segment, target type, target id, property, and interpolation summaries.

Target ids are treated as identifiers only, not filesystem paths.

## Adapter Summary

Adapter summary is derived from the M36.7 operation plan:

- `operation_count`
- `operation_types`
- `resolved_target_ids`
- `execution_status = "not_executed"`

Resolved target ids keep first-seen `resolve_target` operation order with duplicates removed.

## Output File References

Output references are copied from the canonical animation plan as runtime-relative strings:

- preview: `media/animation/previews/...`
- metadata: `media/animation/metadata/...`

The writer does not check whether those files exist and does not create runtime files.

## Created-at Behavior

Production CLI calls use current UTC with second precision:

```text
YYYY-MM-DDTHH:MM:SSZ
```

Tests can inject a fixed timestamp through `build_animation_metadata_sidecar(..., created_at="2026-01-01T00:00:00Z")`. Invalid injected timestamps are rejected.

## Plan-only Mode

Default CLI behavior prints a writer report to stdout and writes no files:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_metadata_sidecar.py \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --pretty
```

In plan-only mode, `metadata.safety_flags.metadata_written` remains `false`.

## Explicit Write Mode

`--write-metadata` writes only to an absolute `/tmp/*.json` path:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_metadata_sidecar.py \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --write-metadata /tmp/moe-animation-metadata/object-transform-demo.json \
  --pretty
```

The written payload has `metadata_written=true`. Other safety flags remain false.

## Output Path Safety

Write paths must be absolute `/tmp` JSON paths. The writer rejects relative paths, repo paths, runtime paths, model backup paths, `/home`, `/mnt`, `/media`, traversal, non-JSON extensions, destination symlinks, and parent symlinks.

Parent directories may be created under `/tmp`.

## Atomic Write Behavior

The writer creates a temporary file beside the destination, writes UTF-8 JSON with sorted keys and a trailing newline, flushes, calls `fsync`, and then uses `os.replace`.

Temporary files are cleaned up on failure.

## Safety Flags

Plan-only safety flags include:

- `metadata_written=false`
- `read_only_inputs=true`
- `runtime_assets_written=false`
- `source_assets_modified=false`
- `generation_triggered=false`
- `blender_execution_attempted=false`
- `keyframes_written=false`
- `scene_modified=false`
- `preview_render_attempted=false`
- `external_process_started=false`
- `blend_file_saved=false`

## CLI

Allowed arguments:

- `--adapter-request PATH`
- `--write-metadata PATH`
- `--pretty`

No execution, render, save, runtime-root, output-root, ffmpeg, Blender, or shell arguments are supported.

## Exit Codes

- `0`: metadata plan printed or `/tmp` sidecar written
- `1`: adapter, canonical, timeline, operation, or metadata contract validation failed
- `2`: path, load, malformed JSON, output, or tooling error

## Runtime Boundary

M36.8 does not create or use `/home/cuneyt/MoE/runtime/media/animation/metadata`.

Only explicit `/tmp` writes are supported for review/testing.

## M36.9 Boundary

M36.9 adds the read-only animation metadata validator as a separate CLI and schema. M36.8 still only plans or writes metadata.

## Non-goals

M36.8 does not implement Blender execution, `bpy` imports, keyframe writes, scene mutation, preview rendering, frame rendering, video encoding, ffmpeg, `.blend` save, asset import/export, Gateway endpoints, Dashboard changes, reference-board integration, Docker services, or runtime metadata writes.

## Test Coverage

Run:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
make test-animation-metadata-sidecar-writer
```

The regression covers plan-only metadata, fixed and current timestamps, hash consistency, timeline mismatch rejection, `/tmp` atomic writes, output path restrictions, symlink rejection, import safety, execution non-use, and source-only artifact checks.

## Final Decision

M36.8 is complete when the writer, docs, review template, layout entry, Make target, roadmap updates, and non-Blender regression pass. M36.9 validates the metadata contract separately.
