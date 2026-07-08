# Drawing Metadata Sidecar Implementation

## What Was Implemented

M34.7 adds runtime JSON sidecar metadata generation for deterministic SVG drawing outputs.

## Affected Tools

- `tools/pergola-drawings/generate_pergola_svg.py`
- `tools/drawing-engine/generate_demo_svg.py`

## Generated Sidecar Files

Pergola drawing sidecars:

- `overview_skeleton.svg` -> `overview_skeleton.json`
- `side_elevation.svg` -> `side_elevation.json`
- `top_plan.svg` -> `top_plan.json`

Generic drawing engine demo sidecar:

- `demo_sheet.svg` -> `demo_sheet.json`

## Schema Summary

Drawing sidecars include:

- `schema_version`
- `asset_type`
- `asset_name`
- `asset_path`
- `relative_runtime_path`
- `created_at`
- `source`
- `script`
- `project`
- `drawing_kind`
- `units`
- `geometry`
- `safety_label`
- `notes`

JSON is written with indentation and sorted keys.

## Runtime-only Policy

Metadata sidecars are runtime output. They are written next to generated SVG files and are not committed by default.

## Output Card Integration

The output card API already looks for sidecar JSON files with the same basename. After these generators run, deterministic SVG drawing cards can show `metadata_available: true`.

Troubleshooting: if sidecar files exist on the host but `/gateway/media/output-cards` returns no `drawing_svg` cards, verify `gateway-api` has read-only runtime volume access to `/home/cuneyt/MoE/runtime/pergola/drawings` and `/home/cuneyt/MoE/runtime/drawings`.

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
python3 tools/pergola-drawings/generate_pergola_svg.py
```

### Run on PC-1
```bash
python3 tools/drawing-engine/generate_demo_svg.py
```

## How To Inspect Metadata

### Run on PC-1
```bash
find /home/cuneyt/MoE/runtime/pergola/drawings /home/cuneyt/MoE/runtime/drawings/demo \
  -maxdepth 1 -type f \( -name '*.svg' -o -name '*.json' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

### Run on PC-1
```bash
jq . /home/cuneyt/MoE/runtime/pergola/drawings/side_elevation.json
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq '.cards[] | select(.name == "side_elevation.svg")'
```

## Safety Constraints

- Do not run image generation.
- Do not alter ComfyUI scripts.
- Do not create image metadata yet.
- Do not create PDF or DXF.
- Do not delete, move, or rename runtime files.
- Do not store secrets, API keys, or shell history in metadata.

## What Is NOT Implemented Yet

- image generation metadata
- full metadata display drawer
- preview serving
