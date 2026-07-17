# 3D Reference Board Selection

M35.19 adds dashboard selection for verified 3D output cards.

The selection writes only reference metadata to:

```text
/home/cuneyt/MoE/runtime/reference-boards/*.json
```

It does not copy, move, delete, regenerate, repair, or modify 3D assets.

## What Was Implemented

- A dedicated Gateway endpoint:

```text
POST /gateway/media/reference-boards/{board_id}/items/3d
```

- A server-side 3D card resolver that searches only hardened 3D output cards from:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

- Dashboard `Add to board` controls on 3D output cards.
- Reference-board item display that treats `3d_model` entries as metadata references.

## Request Shape

Allowed request fields:

```json
{
  "card_id": "3d_model:metadata/example.json",
  "selected_reason": "Selected from dashboard 3D output cards.",
  "tags": ["3d", "architecture", "glb"]
}
```

The client must not send paths, names, asset types, safety labels, formats, verification fields, or metadata content. Those values are resolved server-side from the verified 3D card.

## Stored Item Fields

The board item stores:

- `item_id`
- `card_id`
- `asset_type`
- `name`
- `relative_runtime_path`
- `metadata_path`
- `selected_reason`
- `tags`
- `safety_label`
- `added_at`

`asset_type` is stored as `3d_model`.

## Runtime Path Selection

The server chooses the board reference path from `ThreeDOutputCard.relative_runtime_paths`:

1. verified `glb`
2. verified `blend`
3. verified `obj`
4. safe metadata path fallback

If artifacts are missing but the metadata sidecar is valid enough to produce a card, the board can still store a metadata fallback for review-only use.

## Dashboard Behavior

- `Add to board` is disabled until a board is selected.
- Only the clicked 3D card shows loading state.
- Duplicate selection shows `Already in board.`
- Success shows `Added 3D reference to board.`
- 3D board items do not call the generic output-card metadata endpoint.

## Safety Rules

- No 3D asset is copied.
- No 3D asset is modified.
- No metadata sidecar is modified.
- No `.blend`, `.glb`, `.obj`, `.fbx`, or `.mtl` file is written.
- No Blender, Docker, shell, generation, repair, or cleanup action is triggered.

## How To Review

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-reference-board-selection
```

### Run on PC-1

```bash
ALLOW_UI_TEST_NETWORK=1 make test-3d-output-cards-ui
```

### Open in browser

```text
http://127.0.0.1:8500/#media
```

Expected:

- A reference board is selected.
- 3D output cards show `Add to board`.
- Adding a 3D card creates a board reference only.
- Duplicate add is controlled.
- No copy, move, delete, regenerate, repair, or modify action exists.
