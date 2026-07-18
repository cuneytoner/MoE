# Animation Artifact Verifier

## Purpose

M36.12 adds a read-only verifier for animation metadata and sampled PNG preview artifacts. It checks metadata validity, optional provenance, optional preview renderer reports, runtime-relative output references, PNG frame files, file sizes, hashes, timeline consistency, and safety flags.

## Verifier source

Source:

```text
apps/media-worker/app/animation_artifact_verifier.py
```

The module is importable with normal Python. It does not import Blender modules, execute animation plans, render frames, encode video, repair metadata, or write reports.

## Verification modes

The verifier derives its mode from the provided inputs:

- `metadata_only`: metadata standalone validation.
- `metadata_provenance`: metadata plus adapter request provenance.
- `preview_plan`: metadata plus plan-only preview renderer report.
- `preview_artifacts`: metadata plus rendered preview report and frame directory verification.
- `full`: metadata provenance plus rendered preview report and frame verification.

The mode is not user-supplied.

## Metadata validation reuse

Metadata validation reuses the M36.9 animation metadata validator. The verifier does not copy schema logic, repair metadata, or invent missing fields.

## Metadata provenance

When an adapter request is provided, the verifier reuses M36.9 provenance validation. It checks source request hash, adapter request hash, canonical plan hash, operation plan hash, timeline source hash, and rebuilt metadata consistency.

## Runtime metadata verification

Runtime metadata files are accepted only as direct JSON children of:

```text
/home/cuneyt/MoE/runtime/media/animation/metadata
```

If the input is a runtime metadata file, `output_files.metadata` must point to the same runtime-relative file. Config and `/tmp` fixtures are validated as inputs but are not listed as runtime artifacts.

## Preview report validation

Preview reports are accepted only from `/tmp/<file>.json` or direct children of:

```text
/home/cuneyt/MoE/runtime/media/animation/reports
```

Plan-only preview reports validate the operation plan and safety flags but do not require frame files. Rendered reports must include a rendered result and matching sampled frame artifacts.

## Plan-only preview behavior

Plan-only preview reports must have `status=planned`, `planned=true`, `rendered=false`, and `render_result=null`. Runtime frame directories are not inspected for this mode.

## Rendered preview behavior

Rendered preview reports must describe sampled PNG frames only. The verifier checks render result fields, execution flags, preview safety flags, frame list, runtime path, output byte total, and frame files.

## Metadata preview reference behavior

When metadata has `preview_available=false`, the future video preview path in `output_files.preview` is not required to exist. M36.12 verifies sampled PNG frame sets only through a supplied preview renderer report.

## Runtime roots

Production roots are fixed:

```text
/home/cuneyt/MoE/runtime
/home/cuneyt/MoE/runtime/media/animation
/home/cuneyt/MoE/runtime/media/animation/metadata
/home/cuneyt/MoE/runtime/media/animation/previews
/home/cuneyt/MoE/runtime/media/animation/reports
```

The public CLI does not accept a runtime root override.

## Path safety

Runtime artifact references must be POSIX relative paths. Absolute paths, traversal, dot segments, backslashes, URLs, drive prefixes, repo markers, and model backup markers are rejected.

## Symlink protection

Metadata inputs, preview reports, preview-id directories, frame directories, frame files, and existing parent components are checked for symlinks before artifact verification succeeds.

## Frame directory contract

Rendered preview frame directories must be direct runtime paths of the form:

```text
media/animation/previews/<preview-id>/frames
```

Only direct children are inspected. Recursive scanning is not used. Directories with more than 64 entries fail verification.

## Frame filename contract

Each expected frame must use:

```text
frame-000001.png
```

The concrete filename is generated as `frame-{frame:06d}.png`. Missing frames, unexpected PNGs, temporary files, hidden staging files, subdirectories, symlinks, and non-regular files fail verification.

## PNG header verification

The verifier performs minimal PNG validation without a new image dependency:

- exact 8-byte PNG signature
- first chunk length is 13
- first chunk type is `IHDR`

It does not perform full PNG decode or CRC validation.

## Dimension verification

IHDR width and height must match the rendered preview report. Width and height must stay within the M36.11 preview bounds.

## File hashing

Every verified runtime artifact gets a streamed SHA-256 hash using fixed-size chunks. The verifier does not load large files into memory at once.

## Output size consistency

Rendered reports must have `total_output_bytes` equal to the sum of verified frame file sizes. The verified total must stay at or below 512 MiB.

## Timeline consistency

Preview frames must be strictly increasing, unique, integer values within the metadata timeline. Operation plan and render result frame lists must match exactly.

## Artifact records

Runtime metadata files and verified PNG frames are reported with role, runtime-relative path, media type, size, SHA-256, and frame number where applicable. Absolute runtime roots are not included.

## Verification report

Reports use:

```text
report_type = animation_artifact_verification
```

The report is deterministic and contains no timestamps, UUIDs, hostnames, environment dumps, tracebacks, process ids, absolute repo paths, absolute runtime roots, full metadata payloads, or full preview reports.

## Determinism

The same inputs produce the same report bytes. Issue ordering is deterministic by path, code, and message. Artifact ordering keeps metadata first and preview frames in frame order.

## CLI

Metadata-only:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_artifact_verifier.py \
  --metadata configs/animation/animation-metadata.example.json \
  --pretty
```

With provenance:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_artifact_verifier.py \
  --metadata /tmp/animation-metadata.json \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --pretty
```

With preview report:

```bash
PYTHONDONTWRITEBYTECODE=1 \
python3 apps/media-worker/app/animation_artifact_verifier.py \
  --metadata /tmp/animation-metadata.json \
  --adapter-request configs/animation/blender-animation-adapter-request.example.json \
  --preview-report /tmp/animation-preview-report.json \
  --pretty
```

## Exit codes

- `0`: requested artifact set verified.
- `1`: metadata, provenance, preview report, or artifact verification failed.
- `2`: input path, load, malformed JSON, or tooling error.

## Read-only boundary

The verifier does not write metadata, write reports, render frames, repair files, delete files, run Blender, start services, call Gateway, or trigger generation.

## M36.13 boundary

M36.13 Animation Output Card API Plan remains planned. M36.12 does not add Gateway endpoints, Dashboard cards, reference-board integration, or output-card APIs.

## Non-goals

No MP4/WebM/GIF validation, no video encoding, no image decoding dependency, no runtime cleanup, no metadata repair, no frame repair, no Docker changes, and no generated source artifacts are included.

## Test coverage

Regression coverage is in:

```bash
make test-animation-artifact-verifier
```

The tests use `/tmp` fixtures and fake PNG-like files, then clean them up.

## Final decision

M36.12 is a read-only verification milestone. It verifies existing animation metadata and sampled PNG preview artifacts without creating or modifying runtime assets.
