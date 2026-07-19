# Animation Output Card API

## Purpose

M36.14 implements a read-only Gateway API for animation output cards. It discovers validated animation metadata and verified sampled PNG preview reports under the fixed runtime animation scope.

## Gateway module

Gateway uses `apps/gateway-api/app/media_animation_output_cards.py`.

Public builder:

```python
def build_animation_output_cards() -> dict[str, Any]:
    ...
```

Test helper:

```python
def _build_animation_output_cards_from_root(runtime_root: str | Path) -> dict[str, Any]:
    ...
```

The public builder does not accept runtime-root, path, card-id, or preview parameters.

## Shared validation boundary

M36.14 adds `packages/animation-validation/animation_validation/` for pure read-only validation. The media-worker validator and verifier remain compatibility wrappers, while Gateway imports the shared package directly.

## Container-safe imports

Gateway Docker image copies only Gateway app code, `packages/animation-validation`, and `configs/animation`. It does not depend on `/workspace` for validation imports and does not copy runtime artifacts, model files, or the full source tree into the image.

## Endpoint

```text
GET /gateway/media/animation/cards
```

The route is a sync `def`, accepts no query parameters, and returns JSON only.

## Runtime roots

The fixed runtime scope is:

```text
runtime/media/animation
```

Gateway mounts `/home/cuneyt/MoE/runtime/media/animation` read-only in Docker. Missing runtime directories return `status=ok`, empty cards, and warnings.

## Metadata discovery

Metadata files are scanned only as direct children of:

```text
/home/cuneyt/MoE/runtime/media/animation/metadata
```

Nested directories, hidden files, symlinks, non-JSON files, oversized files, malformed JSON, invalid UTF-8, and root arrays do not produce cards.

## Report discovery

Preview reports are scanned only as direct children of:

```text
/home/cuneyt/MoE/runtime/media/animation/reports
```

Only `report_type=animation_preview_renderer` JSON objects are considered.

## Validation reuse

Gateway reuses the shared M36.9 metadata structure and semantic validators. Runtime metadata must also declare the same runtime-relative `output_files.metadata` path as the actual sidecar being scanned.

## Card construction

Cards use stable ids:

```text
animation:<metadata-runtime-relative-path>
```

Cards expose animation metadata, timeline, summary, preview state, runtime-relative paths, verification summary, and review safety fields.

## Metadata-only cards

Valid metadata creates a card even when no preview report exists. Future encoded video declarations are shown only as `declared_video_preview`; missing MP4/WebM/GIF files do not invalidate the card.

## Preview matching

Rendered preview reports match metadata only by exact `source_kind`, `source_request_sha256`, and `canonical_plan_sha256` values from the report operation plan.

## Artifact verification

When exactly one rendered report matches, Gateway calls the shared M36.12 artifact verifier. Preview availability requires a valid rendered report, verified frame directory, expected PNG frame set, final publish, no partial output, and restored render settings.

## Ambiguous reports

If multiple rendered reports match one metadata file, Gateway keeps the metadata card but sets `preview.available=false` and emits an `ambiguous_preview_reports` warning.

## Path safety

Responses contain runtime-relative POSIX paths only. No absolute runtime path, source checkout path, model path, inode, mtime, ctime, UUID, hostname, process id, or current timestamp is returned.

## Warning safety

Warnings use sanitized labels such as `metadata/example.json`, `reports/example.json`, or `animation card <animation-id>`. Warning count is capped.

## Determinism

Metadata files, reports, cards, and warnings are processed deterministically by filename and card id. The same fixture should produce identical response bytes.

## Failure isolation

Missing roots, malformed sidecars, malformed reports, symlinks, oversized files, and missing preview frames should not produce HTTP 500. The endpoint returns `status=ok` with warnings whenever possible.

## Docker integration

Gateway Docker build context is the repo root, but the Dockerfile copies only required source paths:

```text
apps/gateway-api/app
packages/animation-validation
configs/animation
```

The animation runtime mount is read-only.

## Container smoke test

Operator smoke test:

```bash
docker compose -f infra/docker/docker-compose.yml up -d --build --no-deps gateway-api
curl -fsS http://127.0.0.1:8100/gateway/media/animation/cards | jq .
```

Expected service:

```text
gateway-animation-output-cards
```

## Read-only boundary

The API does not generate animation, render previews, execute Blender, call subprocess, encode video, write metadata, repair artifacts, delete files, serve binaries, expose arbitrary paths, or add Dashboard UI.

## M36.15 Dashboard consumption

M36.15 consumes this endpoint in the Dashboard through read-only animation cards. The UI displays metadata, timeline, summary, verified sampled-preview status, runtime-relative paths, and verification fields without serving binaries, loading sampled PNG frames, adding downloads, or adding reference-board actions.

## Final decision

M36.14 implements the read-only animation output card API. M36.15 adds read-only Dashboard consumption and still leaves binary preview serving, downloads, generation, rendering, and reference-board selection to later reviewed milestones.
