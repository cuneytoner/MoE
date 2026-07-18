# Animation Metadata Validator

## Purpose

M36.9 adds a read-only validator for animation metadata sidecar JSON produced by M36.8.

## Validator Source

Source:

```text
apps/media-worker/app/animation_metadata_validator.py
```

The validator runs with normal `python3` and does not import Blender.

## Canonical Metadata Schema

Schema:

```text
configs/animation/animation-metadata.schema.json
```

The schema uses JSON Schema Draft 2020-12 and local `$id`:

```text
urn:moe:animation-metadata-schema:1.0
```

## Metadata Example

Example:

```text
configs/animation/animation-metadata.example.json
```

The example is source-only, uses a fixed timestamp, contains runtime-relative preview and metadata references, and has `execution_status=not_executed`.

## Input Path Security

Metadata input is limited to `configs/animation/*.json` and `/tmp/*.json` style paths. Files must be regular `.json`, non-symlink, traversal-free, UTF-8, and at most 512 KiB.

The validator does not read runtime metadata roots or model backup paths.

## Standalone Validation

Standalone validation checks metadata structure and semantics without an adapter request:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_metadata_validator.py \
  --metadata configs/animation/animation-metadata.example.json \
  --pretty
```

Reports use `validation_mode=standalone` and `provenance_checked=false`.

## Provenance Validation

Provenance validation adds the original adapter request:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_metadata_validator.py \
  --metadata configs/animation/animation-metadata.example.json \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --pretty
```

The validator reloads the adapter request with the M36.7 loader, validates it, regenerates the operation plan, rebuilds metadata with the M36.8 writer, and compares canonical JSON.

## Structural Contract

The validator checks required fields, constants, strict nested objects, hash formats, source kind, identifiers, validation flags, warnings, and safety flags.

## Timeline Consistency

Timeline checks include integer FPS and frame bounds, `total_frames == end_frame - start_frame + 1`, and `duration_seconds == total_frames / fps` within tolerance.

## Animation Summary

Animation summary checks track/keyframe/segment counts, sorted unique target types, sorted unique target ids, sorted unique properties, and sorted unique interpolations.

## Adapter Summary

Adapter summary checks operation count, sorted unique allowlisted operation types, deterministic unique resolved target ids, and `execution_status=not_executed`.

## Output Paths

Output paths must be normalized runtime-relative POSIX strings:

- `media/animation/previews/...`
- `media/animation/metadata/...`

The validator does not check file existence.

## Hash Validation

Standalone validation checks 64 lowercase hex format. Provenance validation recomputes adapter request, canonical plan, and operation plan hashes.

## Timestamp Validation

`created_at` must use `YYYY-MM-DDTHH:MM:SSZ` and parse as a real calendar timestamp. The validator does not reject future timestamps.

## Validation Flags

All validation flags inside metadata must be `true`.

## Safety Flags

`metadata_written` may be true or false. `read_only_inputs` must be true. Runtime writes, source modifications, generation, Blender execution, keyframes, scene mutation, preview render, external process, and blend save flags must all be false.

## Validation Report

Reports include only safe summary fields, deterministic error/warning lists, and safety flags. They do not embed full metadata or adapter request payloads.

## CLI

Allowed arguments:

- `--metadata PATH`
- `--adapter-request PATH`
- `--pretty`

## Exit Codes

- `0`: metadata valid
- `1`: loaded metadata failed structural, semantic, or provenance validation
- `2`: path, load, malformed JSON, schema, or tooling error

## Read-only Boundary

M36.9 writes no files, reads no runtime metadata root, does not inspect runtime asset existence, and does not access model files.

## M36.10 Boundary

M36.10 adds preview render safety planning as a source-only contract. M36.9 does not add preview rendering or render controls.

## Non-goals

M36.9 does not repair metadata, rewrite metadata, scan runtime, render previews or frames, encode video, use ffmpeg, execute Blender, import `bpy`, write keyframes, mutate scenes, save `.blend`, add Gateway endpoints, add Dashboard changes, add reference-board integration, or add Docker services.

## Test Coverage

Run:

```bash
### Run on PC-1
cd ~/DiskD/Projects/MoE/codebase
make test-animation-metadata-validator
```

The regression covers source examples, writer output, standalone validation, provenance validation, malformed input, structural and semantic mutations, hash mismatches, rebuild mismatches, deterministic reports, symlink rejection, oversized input rejection, no Blender imports, no execution, no writes, and source-only artifact audits.

## Final Decision

M36.9 is complete when the validator, schema, example, docs, review template, layout entry, Make target, roadmap updates, and read-only regressions pass. M36.10 now carries the separate preview render safety plan.
