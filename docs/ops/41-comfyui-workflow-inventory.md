# 41 ComfyUI Workflow Inventory

This document records the current successful Flux Schnell ComfyUI workflow after the first real image generation.

It is for beginner-safe inspection and future review. It does not replace the guarded generation drill.

This workflow inventory supports both the direct ComfyUI first-image path and future Gateway/media real runs when they use the same workflow.

## What This Document Is For

- Explain which workflow file produced the first successful image.
- Record the model files and ComfyUI linked paths used by the workflow.
- Show where runtime workflow files and output images live.
- Provide safe read-only commands for inspecting the workflow.
- Give a simple rule for recording future workflow changes.

## What This Document Does NOT Do

- It does not run real image generation.
- It does not edit the workflow JSON.
- It does not download, copy, delete, or modify model files.
- It does not change Gateway behavior.
- It does not change Docker Compose behavior.
- It does not add automatic generation or shell execution features.

## Successful Workflow File

The successful workflow JSON is:

```text
/home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json
```

This file is runtime data. It is not stored inside the source repo.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
```

### Run on PC-1

```bash
test -f /home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json && echo "workflow exists"
```

Expected good sign: `workflow exists`.

## Successful Output Example

The first successful output image was:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

The output is outside the repo, which is the expected safe layout.

## Model File Inventory

Known source model files:

| Purpose | Model file |
| --- | --- |
| Flux Schnell UNet | `/home/cuneyt/MoE_Models_Backup/flux/flux1-schnell.safetensors` |
| VAE | `/home/cuneyt/MoE_Models_Backup/vae/ae.safetensors` |
| CLIP text encoder | `/home/cuneyt/MoE_Models_Backup/clip/clip_l.safetensors` |
| T5 text encoder | `/home/cuneyt/MoE_Models_Backup/clip/t5xxl_fp8_e4m3fn.safetensors` |

Model files stay in `/home/cuneyt/MoE_Models_Backup`. Do not copy them into the repo.

## Linked ComfyUI Model Paths

Known ComfyUI linked paths:

| Purpose | ComfyUI path |
| --- | --- |
| Flux Schnell UNet | `/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/unet/flux1-schnell.safetensors` |
| VAE | `/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/vae/ae.safetensors` |
| CLIP text encoder | `/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/clip/clip_l.safetensors` |
| T5 text encoder | `/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/text_encoders/t5xxl_fp8_e4m3fn.safetensors` |

Inspect the linked model tree read-only:

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models \
  -maxdepth 3 -type l -o -type f | sort | grep -Ei 'flux|clip|t5|vae|ae|safetensors'
```

Expected good sign: the Flux, CLIP, T5, and VAE files appear under the ComfyUI runtime model folders.

## Runtime Folders

Important runtime folders:

| Folder | Purpose |
| --- | --- |
| `/home/cuneyt/MoE/runtime/media/workflows` | Runtime workflow JSON files |
| `/home/cuneyt/MoE/runtime/media-engines/comfyui` | ComfyUI runtime engine |
| `/home/cuneyt/MoE/runtime/media/outputs/images` | Generated image output root |
| `/home/cuneyt/MoE_Models_Backup` | Model file storage outside runtime and repo |

These folders are outside `/home/cuneyt/DiskD/Projects/MoE/codebase`.

## Output Folders

The first successful Flux output folder is:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

List recent PNG outputs:

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/outputs/images/flux-first \
  -maxdepth 1 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -20
```

Expected good sign: generated PNG paths stay under `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first`.

## Parameters Used In First Success

| Parameter | Value |
| --- | --- |
| Prompt | `realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight` |
| Size | `512x512` |
| Steps | `4` |
| Seed | `1783334081` |
| Workflow JSON | `/home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json` |
| ComfyUI URL | `http://127.0.0.1:8188` |
| Output folder | `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first` |

See [42-flux-schnell-parameter-guide.md](42-flux-schnell-parameter-guide.md) for parameter notes.

## What Can Be Safely Changed

For a beginner, the safest future changes are:

- Prompt text
- Seed value
- Filename prefix
- Output note metadata
- Small parameter notes in documentation

Make one change at a time, then record it in [43-comfyui-workflow-change-log.md](43-comfyui-workflow-change-log.md).

## What Should Not Be Changed Yet

Do not change these until there is a separate reviewed milestone or runbook:

- Model file locations
- Linked ComfyUI model paths
- ComfyUI engine install location
- Docker Compose behavior
- Gateway runtime behavior
- Automatic image generation gates
- Workflow node structure beyond reviewed parameter edits

Do not edit runtime workflow JSON casually. Treat it as operational state.

## How To Inspect The Workflow JSON Safely

This command formats the workflow JSON for reading. It does not edit the file.

### Run on PC-1

```bash
python3 -m json.tool /home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json | head -120
```

Expected good sign: the JSON prints in readable form and no write operation occurs.

## How To Record Future Workflow Changes

When a workflow parameter changes:

1. Record the date/time.
2. Record the Git commit before the run.
3. Record the workflow path.
4. Record exactly what changed and why.
5. Record prompt, size, steps, seed, output path, and result.
6. Run the Git safety check from [37-generated-image-git-safety.md](37-generated-image-git-safety.md).
7. Do not commit generated image binaries.

Use [43-comfyui-workflow-change-log.md](43-comfyui-workflow-change-log.md) as the manual changelog template.
