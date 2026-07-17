# 3D Output Card API

M35.17 adds read-only Gateway API support for future 3D output cards.

## What Was Implemented

- `apps/gateway-api/app/media_3d_output_cards.py`
- `GET /gateway/media/3d/cards`
- `scripts/test-3d-output-card-api.sh`
- `make test-3d-output-card-api`

The API discovers 3D cards from metadata sidecars only. It does not scan arbitrary paths, run Blender, generate assets, write runtime files, or expose delete/move/rename/repair/generation actions.

## Endpoint Path

```text
GET /gateway/media/3d/cards
```

The response service name is:

```text
gateway-3d-output-cards
```

## Card Discovery Source

Default runtime root:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Metadata directory:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d/metadata
```

Only `.json` sidecars under the metadata directory are scanned. Missing metadata directories return an empty card list with a warning.

## Card Response Shape

Example card:

```json
{
  "id": "3d_model:metadata/simple_frame_example-test.json",
  "type": "3d_model",
  "asset_name": "simple_frame_example",
  "asset_category": "architecture",
  "created_at": "2026-07-17T00:00:00Z",
  "formats": ["blend", "glb"],
  "preview_available": false,
  "metadata_path": "metadata/simple_frame_example-test.json",
  "relative_runtime_paths": {
    "blend": "blender/simple_frame_example-test.blend",
    "glb": "glb/simple_frame_example-test.glb",
    "obj": null,
    "preview": null,
    "metadata": "metadata/simple_frame_example-test.json",
    "report": "reports/simple_frame_example-test.json"
  },
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "operator_review_required": true,
  "generation_mode": "guarded_blender",
  "verification": {
    "valid": true,
    "error_count": 0
  }
}
```

List response:

```json
{
  "status": "ok",
  "service": "gateway-3d-output-cards",
  "runtime_root": "/home/cuneyt/MoE/runtime/media/outputs/3d",
  "metadata_dir_available": true,
  "card_count": 1,
  "invalid_count": 0,
  "cards": [],
  "warnings": [],
  "safety_flags": {
    "read_only": true,
    "generation_triggered": false,
    "runtime_assets_written": false,
    "source_assets_modified": false,
    "shell_execution": false
  }
}
```

## Runtime-Relative Path Policy

Card payloads expose runtime-relative paths only, such as:

```text
metadata/simple_frame_example-test.json
glb/simple_frame_example-test.glb
reports/simple_frame_example-test.json
```

The API rejects or skips:

- absolute output paths
- path traversal
- repo-looking paths such as `docs/`, `apps/`, `scripts/`, and `configs/`
- model backup-looking paths
- symlink metadata directories
- symlink sidecar files
- non-JSON sidecar files

## Missing And Malformed Metadata Behavior

Missing metadata directory:

- `status=ok`
- `metadata_dir_available=false`
- `card_count=0`
- warning included

Malformed or unsafe sidecars:

- skipped from valid cards
- counted in `invalid_count`
- warning included
- no traceback exposed

## Safety Flags

The endpoint returns:

```json
{
  "read_only": true,
  "generation_triggered": false,
  "runtime_assets_written": false,
  "source_assets_modified": false,
  "shell_execution": false
}
```

## Boundaries

The M35.17 API does not:

- run Blender
- import `bpy`
- generate `.blend`, `.glb`, `.obj`, `.fbx`, or `.mtl` files
- create runtime sidecars
- write reports
- create previews
- expose raw host absolute asset paths
- accept arbitrary filesystem paths
- add delete, cleanup, repair, rename, move, or generation endpoints

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-output-card-api
```

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
```

Expected test output:

```text
3D output card API OK
```

## Fixed Roadmap

- M35.17 3D Output Card API DONE
- M35.18 Dashboard 3D Output Cards UI PLANNED
- M35.19 3D Reference Board Selection PLANNED
- M35.20 M35 Phase Closure PLANNED
