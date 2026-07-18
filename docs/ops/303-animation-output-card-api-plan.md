# Animation Output Card API Plan

## Purpose

M36.13 plans a read-only Gateway output-card API for animation metadata and sampled PNG preview artifacts. It defines the future endpoint, runtime discovery contract, response shape, card fields, preview rules, warning behavior, and regression expectations without implementing Gateway or Dashboard code.

## Scope

This milestone creates the plan, response example, review template, regression script, Make target, and roadmap updates. It does not add an endpoint or runtime scanner.

## Non-goals

No FastAPI endpoint implementation, Dashboard UI, preview binary serving, FileResponse, Blender execution, animation execution, preview rendering, metadata writing, report writing, artifact repair, runtime cleanup, ffmpeg, subprocess, Docker service, or M36.14 implementation is included.

## Existing 3D output-card lessons

The M36.14 implementation must avoid issues seen or reviewed around earlier output-card work:

- no public runtime_root parameter
- no absolute runtime path response
- no recursive `rglob`, `glob("**/*")`, or `os.walk`
- no unbounded sidecar or report scan
- no nested metadata directories
- no symlink following
- no exception text leakage
- no blocking filesystem scan inside an async endpoint
- no card production before metadata validation
- clearly separate declared future artifacts from existing verified artifacts

## Planned endpoint

Planned endpoint for M36.14:

```text
GET /gateway/media/animation/cards
```

Planned route shape:

```python
@app.get("/gateway/media/animation/cards")
def media_animation_output_cards() -> dict[str, Any]:
    return build_animation_output_cards()
```

The route must be sync `def`, read-only, body-less, and free of runtime-root, output-path, execution, generation, Blender, service, shell, or filesystem mutation controls.

## Gateway module boundary

Planned source for M36.14:

```text
apps/gateway-api/app/media_animation_output_cards.py
```

Planned public function:

```python
def build_animation_output_cards() -> dict[str, Any]:
    ...
```

The production function must not accept a runtime root parameter. A private test helper may exist:

```python
def _build_animation_output_cards_from_root(runtime_root: str | Path) -> dict[str, Any]:
    ...
```

That helper is for unit/regression fixtures only.

## Runtime scope

The public response must expose only:

```text
runtime/media/animation
```

It must not expose `/home/cuneyt/MoE/runtime` or other host absolute paths.

## Metadata discovery

Metadata is the only required card source. M36.14 should scan only direct children of:

```text
/home/cuneyt/MoE/runtime/media/animation/metadata
```

Accepted metadata files must be direct-child, non-hidden, non-symlink, regular `.json` files, at most 512 KiB, valid UTF-8, and root JSON objects.

## Report discovery

Reports are optional and should be scanned only as direct children of:

```text
/home/cuneyt/MoE/runtime/media/animation/reports
```

Only `report_type=animation_preview_renderer` JSON reports are relevant. Invalid reports must not remove otherwise valid metadata cards.

## Direct-child scan rule

M36.14 must use `metadata_dir.iterdir()` and `reports_dir.iterdir()` only. Nested directories are skipped with sanitized warnings and are never opened recursively.

## Scan and file-size limits

Planned limits:

```text
MAX_METADATA_SIDECARS = 200
MAX_PREVIEW_REPORTS = 200
MAX_METADATA_BYTES = 512 KiB
MAX_PREVIEW_REPORT_BYTES = 1 MiB
MAX_WARNINGS = 200
MAX_CARDS = 200
```

Entries are processed filename ascending. Limit overflow skips remaining entries deterministically and adds a sanitized warning.

## Metadata validation reuse

M36.14 should reuse the M36.9 metadata validator or the M36.12 verifier rather than copying metadata schema, semantic, safety, or runtime-path validation into Gateway code. If Gateway import boundaries make direct reuse awkward, M36.14 should choose the smallest safe integration path or extract shared pure validation in a reviewed milestone.

## Artifact verifier reuse

When a rendered preview report matches metadata, M36.14 should call the M36.12 artifact verifier read-only. It must not duplicate PNG signature, IHDR, frame filename, file hash, size, symlink, total byte, or timeline checks.

## Card identity

Stable id:

```text
animation:<metadata-runtime-relative-path>
```

Example:

```text
animation:media/animation/metadata/object-transform-demo.json
```

The id must not use timestamps, UUIDs, inode, mtime, ctime, absolute paths, or inferred filenames. Duplicate ids are skipped with a warning; no silent overwrite.

## Top-level response contract

The top-level response uses:

```text
service = gateway-animation-output-cards
runtime_scope = runtime/media/animation
```

It includes directory availability, counts, cards, warnings, and fixed read-only safety flags. Missing runtime or metadata directories should return `status=ok`, empty cards, and sanitized warnings rather than HTTP 500.

## Card contract

Each card has:

- `id`
- `type=animation`
- metadata fields
- timeline
- summary
- preview state
- runtime-relative paths
- verification summary
- safety review fields

Fields come only from validated metadata and verified preview reports, never from filename guesses.

## Timeline and summary fields

Timeline comes from metadata `timeline`. Summary comes from `animation_summary` and `adapter_summary`. The API must not infer fps, frame range, operation count, title, source kind, target ids, or properties from paths.

## Metadata-only cards

Valid metadata with no preview report still creates a card with `preview.available=false`. Missing future MP4/WebM/GIF files do not make the card invalid.

## Preview report matching

Reports match metadata only when all three fields match exactly:

```text
source_kind
source_request_sha256
canonical_plan_sha256
```

Filename-only, animation-id-only, preview-id-only, mtime, ctime, or alphabetic report selection is forbidden.

## Ambiguous report handling

If multiple rendered reports match one metadata sidecar, `preview.available=false` and a sanitized `ambiguous_preview_reports` warning is emitted. The API must not pick a report by mtime, ctime, or alphabetic order.

## Preview availability

`preview.available=true` only when exactly one matching rendered preview report exists, all source/hash fields match, M36.12 verifier returns `valid=true`, the frame directory and expected PNGs are verified, `final_output_published=true`, `partial_output_available=false`, and `render_settings_restored=true`.

## Future video declaration

Metadata `output_files.preview` is a future video declaration. It should be surfaced only as `declared_video_preview`, if safe and runtime-relative. The API must not look for MP4/WebM/GIF files, serve video, or mix the video declaration with sampled PNG frame availability.

## First-frame path

For verified PNG previews, `first_frame_relative_path` is derived from the render result frame list:

```python
f"{relative_output_directory}/frame-{frames[0]:06d}.png"
```

Directory scan order must not choose the first frame.

## Binary serving boundary

M36.13 and M36.14 do not serve PNG bytes, add `FileResponse`, expose arbitrary preview path routes, build filesystem paths from card ids, or embed base64 images.

## Path safety

All response paths must be runtime-relative POSIX paths. Allowed path classes:

- `media/animation/metadata/*.json`
- `media/animation/previews/<preview-id>/frames`
- `media/animation/previews/<preview-id>/frames/frame-*.png`
- `media/animation/previews/*.(mp4|webm|gif)` as declaration only
- `media/animation/reports/*.json`

Unknown path types are not copied into cards.

## Symlink protection

Animation root, metadata root, report root, metadata files, reports, preview directories, and frame files must not be symlinks. Symlinks are skipped or rejected with sanitized warnings.

## Warning safety

Warnings must avoid absolute source paths, absolute runtime paths, model backup paths, exception reprs, tracebacks, hostnames, environment dumps, shell commands, inode, process id, and timestamps. Warning count is capped with `MAX_WARNINGS`.

## Determinism

Metadata files, reports, cards, and warnings use deterministic ordering. The same runtime fixture must produce identical response bytes. Responses must not contain scan timestamps, current time, mtime, ctime, inode, UUID, process id, or hostname.

## Failure behavior

Individual invalid sidecars or reports do not fail the endpoint. Missing metadata directory returns empty cards and a warning. Invalid metadata increments `invalid_count` and produces no card. Invalid preview reports keep the metadata card and force `preview.available=false`.

## Read-only safety flags

Top-level safety flags are fixed:

```json
{
  "read_only": true,
  "generation_triggered": false,
  "animation_execution_attempted": false,
  "preview_render_attempted": false,
  "runtime_assets_written": false,
  "runtime_assets_modified": false,
  "runtime_assets_deleted": false,
  "source_assets_modified": false,
  "external_process_started": false,
  "shell_execution": false
}
```

Runtime metadata or reports must not override these values.

## M36.14 implementation contract

M36.14 may implement the Gateway module and sync route. It must stay read-only, fixed-root, non-recursive, validation-first, warning-safe, deterministic, and free of Dashboard, binary serving, generation, Blender, Docker, shell, and runtime mutation behavior.

## Test strategy

M36.13 regression checks the plan document, review template, JSON response example, roadmap state, no Gateway/Dashboard implementation, no runtime artifacts, no binary serving plan, and source-only safety.

## Final decision

M36.13 is a planning milestone only. M36.14 implements this plan in `apps/gateway-api/app/media_animation_output_cards.py` and documents the result in `docs/ops/305-animation-output-card-api.md`.
