# Animation Reference Board Selection

## Purpose

M36.16 lets operators add verified animation output cards to existing Reference Boards as metadata references.

## Scope

The milestone connects Dashboard animation cards to the existing reference-board curation store. It does not create a new board system or a new asset store.

## Animation card resolver

Gateway exposes a public resolver:

```python
find_animation_output_card_by_id(card_id: str)
```

It uses the fixed production runtime root and the existing M36.14 animation output card builder.

## Trusted-card boundary

The client sends only `card_id`, `selected_reason`, and `tags`. Gateway resolves the trusted card and derives title, asset type, metadata path, safety label, and verification state from that card.

## Endpoint

```text
POST /gateway/media/reference-boards/{board_id}/items/animation
```

## Request model

```python
class ReferenceBoardAddAnimationItemRequest(BaseModel):
    card_id: str
    selected_reason: str | None = None
    tags: list[str] | None = None
```

Unknown fields are rejected.

## Board item mapping

Animation cards are stored as:

```text
asset_type: animation
name: card.title
relative_runtime_path: card.relative_runtime_paths.metadata
metadata_path: card.relative_runtime_paths.metadata
safety_label: visual-reference-only
```

## Metadata-reference decision

The board item points to the animation metadata sidecar as the stable canonical reference. Preview frames and declared video previews are not used as the primary board path.

## Asset type

The reference-board item validator allows existing known asset types plus `animation`. Unknown asset types remain invalid.

## Relative path policy

Animation metadata references must be relative POSIX paths under:

```text
media/animation/metadata/
```

They must end in `.json` and must not contain absolute paths, backslashes, dot segments, traversal, URLs, or drive prefixes.

## Duplicate handling

Duplicate detection uses `card_id`. A second add of the same animation card returns a conflict and does not write a duplicate item.

## Tag handling

Gateway rebuilds tags from trusted source-derived values and request tags, then validates and deduplicates them with the existing reference-board tag rules.

## Selected reason

`selected_reason` uses the existing reference-board validation and normalization.

## Reference-board store reuse

M36.16 reuses the existing board id validation, fixed reference-board root, board shape validation, duplicate protection, update, remove, read, JSON export, and Markdown export paths.

## Atomic write

The shared reference-board write path now uses a temporary file, flush, fsync, and `os.replace`. Animation-specific code does not implement custom write logic.

## Animation runtime read-only boundary

The only allowed runtime write is the existing reference-board JSON update under:

```text
/home/cuneyt/MoE/runtime/reference-boards
```

The animation runtime remains read-only to Gateway selection logic. Metadata sidecars, sampled PNG frames, preview reports, declared videos, Blender scenes, and source assets are not copied or modified.

## Dashboard API client

Dashboard adds:

```text
addAnimationReferenceBoardItem
```

It posts only `card_id`, `selected_reason`, and `tags`.

## Dashboard handler

`App.tsx` adds an animation add handler that uses the active board, safe frontend tags, existing reference-board refresh, and existing action/error message areas.

## Animation card button

Each animation card can show `Add to board` once a board is selected. Without an active board, the button is disabled and asks the operator to select a board first.

## Error isolation

Animation add failures are shown through the reference-board error state. They do not clear animation cards, fake a successful board update, or block existing image/3D handlers.

## JSON and Markdown export

Animation items appear in existing JSON and Markdown exports as `asset_type=animation` with the metadata-relative path. Binary previews and declared videos are not embedded.

## Container integration

Run on PC-1:

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml build gateway-api
docker compose -f infra/docker/docker-compose.yml up -d --build --no-deps gateway-api
```

## Live verification

Run on PC-1:

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/gateway/media/animation/cards | jq .
curl -fsS http://127.0.0.1:8100/openapi.json |
jq '.paths["/gateway/media/reference-boards/{board_id}/items/animation"].post'
```

Do not POST to a production board during smoke verification.

## M36.17 boundary

M36.17 M36 Phase Closure remains planned. This milestone does not close the phase or start M37/M38.

## Final decision

M36.16 adds safe animation reference-board selection as metadata curation only, reusing existing board storage and preserving animation runtime boundaries.
