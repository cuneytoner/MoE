# Image Generation Service Preparation

Milestone 26.0 prepares image generation without enabling real generation. Milestone 26.1-pre selects the planned engine path and adds read-only runtime/model probes.

These milestones are dry-run and planning only. They do not install ComfyUI, install Diffusers, download models, call GPU jobs, call model runtime, or create image files.

## Scope

- Add image generation configuration placeholders.
- Add image model inventory checks.
- Add image-specific job metadata validation.
- Add dry-run image report fields.
- Keep real generation disabled by default.

## Dry-Run Job Metadata

Example image job:

```json
{
  "job_type": "image",
  "mode": "dry_run",
  "prompt": "text",
  "negative_prompt": "",
  "workflow": "image_default",
  "metadata": {
    "width": 1024,
    "height": 1024,
    "steps": 4,
    "seed": 123,
    "engine": "disabled",
    "model_id": "flux-schnell-placeholder"
  }
}
```

Validation in M26.0:

- `width` and `height` must be positive integers if provided.
- `width` and `height` must be `4096` or less.
- `steps` must be positive if provided.
- `engine` defaults to `disabled`.
- Only `disabled`, `comfyui-placeholder`, and `diffusers-placeholder` are accepted as dry-run metadata.
- Any mode other than `dry_run` is rejected.

## Model Inventory

Inspect optional image model candidates:

```bash
make check-image-models
```

Print the component-level model plan without downloading:

```bash
make plan-image-model-downloads
```

The check inspects only:

```text
/home/cuneyt/MoE_Models_Backup
```

The checks never download or modify model files. They exit successfully even if no image model exists because M26.1-pre does not require one.

Current planning tracks:

- Track A: Flux Schnell via ComfyUI, recommended default.
- Track B: SDXL via ComfyUI, fallback planning track.

The existing inventory may include text encoders or unrelated media model files such as `clip_l`, `t5xxl`, or CogVideo components. A main Flux or SDXL image model is still required before real image generation can be enabled.

## Future Engine Choices

Recommended primary engine:

- ComfyUI

Reasons:

- Better workflow orchestration.
- Future Flux support.
- Future video workflow support.
- Future image-to-video bridge.
- Node workflow exportability.
- Easier media pipeline debugging.

Deferred alternative:

- Diffusers

Reason to defer:

- It is simpler for direct Python generation but less ideal for visual workflow orchestration.

Candidate model families:

- Flux Schnell
- SDXL

These are not enabled in M26.0 or M26.1-pre.

## Runtime Paths

Future image outputs belong under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Dry-run jobs and reports use:

```text
/home/cuneyt/MoE/runtime/media/jobs
/home/cuneyt/MoE/runtime/reports/media
```

No generated image belongs in the source repository.

## Runtime Engine Layout Plan

Planned ComfyUI runtime root:

```text
/home/cuneyt/MoE/runtime/media-engines/comfyui
```

Planned subdirectories:

```text
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI
/home/cuneyt/MoE/runtime/media-engines/comfyui/venv
/home/cuneyt/MoE/runtime/media-engines/comfyui/logs
/home/cuneyt/MoE/runtime/media-engines/comfyui/workflows
```

Model storage remains:

```text
/home/cuneyt/MoE_Models_Backup
```

Future ComfyUI model symlink targets are planned only:

```text
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/checkpoints
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/clip
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/text_encoders
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/vae
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/models/unet
```

Inspect the planned runtime layout without creating anything:

```bash
make check-comfyui-layout
```

Manually create only the planned runtime directories:

```bash
make check-comfyui-layout-create
```

This does not install ComfyUI, create model symlinks, modify model files, or run GPU jobs.

## Safety Gates

- No real generation in M26.0 or M26.1-pre.
- No ComfyUI installation.
- No Blender installation.
- No Diffusers installation.
- No model downloads.
- No model file modifications.
- No GPU job execution.
- No arbitrary shell execution.
- No image output creation.

Future real image generation requires all safety variables to be explicitly enabled:

```text
MEDIA_REAL_GENERATION_ENABLED=false
MEDIA_IMAGE_ENGINE=disabled
MEDIA_COMFYUI_URL=http://127.0.0.1:8188
MEDIA_ALLOW_GPU_JOBS=false
```

Real generation must remain rejected until a later explicit milestone sets the engine, validates model inventory, confirms runtime layout, and adds tests.
