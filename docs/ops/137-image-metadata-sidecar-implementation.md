# Image Metadata Sidecar Implementation

## What Was Implemented

M34.10 adds sidecar JSON metadata generation for new ComfyUI image outputs produced by the first-image script.

When the script detects a newly generated image and surfaces it under the runtime image output folder, it writes a matching `.json` file next to the image.

## Script Affected

```text
scripts/comfyui-first-image.sh
```

The script still supports its existing dry-run behavior. Metadata is written only after `APPLY=1` generation has produced an actual image file.

## Metadata Fields

The sidecar records:

- `schema_version`
- `asset_type`
- `asset_name`
- `asset_path`
- `relative_runtime_path`
- `created_at`
- `source`
- `script`
- `workflow`
- `model_family`
- `model_name`
- `prompt`
- `negative_prompt`
- `width`
- `height`
- `steps`
- `seed`
- `filename_prefix`
- `safety_label`
- `notes`

The script uses the active values for `PROMPT`, `WIDTH`, `HEIGHT`, `STEPS`, `SEED`, and `FILENAME_PREFIX`.

## Sidecar Naming

Use the same basename as the generated image and replace the extension with `.json`.

Example:

```text
moe_pergola_project_20260707_131301_00001_.png
moe_pergola_project_20260707_131301_00001_.json
```

## Runtime-only Policy

Image metadata sidecars are runtime outputs. They belong next to generated image files under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Do not copy generated image sidecars into the repo unless a future reviewed fixture policy explicitly allows it.

## Dashboard / Output-card Integration

The output cards API already matches media files with sidecar JSON using the same basename.

After M34.10, newly generated image cards can show:

```text
metadata_available=true
```

when the image has a matching sidecar JSON file.

M34.15 can display image metadata in the dashboard.

## Safety Rules

- Do not store secrets.
- Do not store API keys.
- Do not store shell history.
- Do not store arbitrary environment dumps.
- Do not add rerun commands.
- Do not trigger generation from the dashboard.
- Do not write metadata into the source repo.

## What Is NOT Implemented Yet

- No metadata detail drawer.
- No dashboard metadata editing.
- No preview serving change.
- No reference-board selection API.
- No image regeneration or rerun action.

## How To Test Without Running Image Generation

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
grep -R "schema_version\|asset_type\|visual_reference_only\|relative_runtime_path" -n scripts/comfyui-first-image.sh
```

### Run on PC-1
```bash
make check-layout
make check-python-syntax
```

Also validate the shell syntax:

### Run on PC-1
```bash
bash -n scripts/comfyui-first-image.sh
```

## How To Test Later With Controlled Image Generation

Only run this after image mode is prepared.

### Run on PC-1 after image mode prepare only
```bash
PROMPT="realistic architectural exterior concept of a small garden studio, practical construction, natural daylight, realistic materials, human-scale proportions, clean composition" \
WIDTH=512 HEIGHT=512 STEPS=4 SEED=1783334081 \
FILENAME_PREFIX="metadata_test_$(date +%Y%m%d_%H%M%S)" \
APPLY=1 scripts/comfyui-first-image.sh
```

Then inspect:

### Run on PC-1
```bash
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -type f \( -name 'metadata_test_*.png' -o -name 'metadata_test_*.json' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```
