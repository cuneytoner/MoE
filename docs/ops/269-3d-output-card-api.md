# 3D Output Card API

M35.17 adds read-only Gateway API support for future 3D output cards.

## What Was Implemented

- `apps/gateway-api/app/media_3d_output_cards.py`
- `GET /gateway/media/3d/cards`
- `scripts/test-3d-output-card-api.sh`
- `make test-3d-output-card-api`

The API discovers 3D cards from metadata sidecars only. It does not scan arbitrary paths, run Blender, generate assets, write runtime files, or expose delete/move/rename/repair/generation actions.

M35.17 security hardening keeps the production endpoint pinned to the fixed 3D runtime root and exposes only a safe runtime scope label in responses.

## Endpoint Path

```text
GET /gateway/media/3d/cards
```

The response service name is:

```text
gateway-3d-output-cards
```

## Card Discovery Source

Production runtime root:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

Metadata directory:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d/metadata
```

Only direct `metadata/*.json` sidecars under the metadata directory are scanned. Recursive scanning is not used.

Missing metadata directories return an empty card list with a warning. Relative roots, repo paths, model backup paths, runtime root symlinks, metadata directory symlinks, and sidecar symlinks are rejected or skipped safely.

## Card Response Shape

Example card:

```json
{
  "id": "3d_model:metadata/simple_frame_example-test.json",
  "type": "3d_model",
  "asset_name": "simple_frame_example",
  "asset_category": "architecture",
  "created_at": "2026-07-17T00:00:00Z",
  "formats": [],
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
    "metadata_valid": true,
    "artifacts_valid": false,
    "valid": false,
    "declared_count": 4,
    "existing_count": 1,
    "missing_count": 3,
    "error_count": 3,
    "errors": [
      "declared blend artifact is missing",
      "declared glb artifact is missing",
      "declared report artifact is missing"
    ]
  }
}
```

`formats` includes only existing regular files that pass directory, extension, runtime-scope, and symlink checks. Missing declared `.blend` or `.glb` files do not appear in `formats`.

List response:

```json
{
  "status": "ok",
  "service": "gateway-3d-output-cards",
  "runtime_scope": "runtime/media/outputs/3d",
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

The exact path allowlist is:

| Key | Allowed path |
| --- | --- |
| `blend` | `blender/*.blend` |
| `glb` | `glb/*.glb` |
| `obj` | `obj/*.obj` |
| `preview` | `previews/*.png`, `previews/*.jpg`, `previews/*.jpeg`, `previews/*.webp` |
| `metadata` | `metadata/*.json` |
| `report` | `reports/*.json` |

The API rejects or skips:

- absolute output paths
- path traversal
- leading `./`
- backslashes
- empty, dot, dot-dot, hidden, null-byte, control-character, URL, drive-prefix, and network path forms
- wrong directory for key
- wrong extension for key
- repo paths
- model backup paths
- artifact symlinks
- runtime root symlinks
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
- absolute host paths are not included in warnings

Metadata-valid sidecars with missing declared artifacts:

- remain visible as cards
- report `verification.valid=false`
- report missing artifact counts and sanitized errors
- do not list missing formats in `formats`
- do not set `preview_available=true`

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
