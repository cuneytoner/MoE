# Image Generation Service Preparation

Milestone 26.0 prepares image generation without enabling real generation.

This milestone is dry-run only. It does not install ComfyUI, install Diffusers, download models, call GPU jobs, call model runtime, or create image files.

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

The check inspects only:

```text
/home/cuneyt/MoE_Models_Backup
```

It never downloads or modifies model files. It exits successfully even if no image model exists because M26.0 does not require one.

## Future Engine Choices

Candidate engines to evaluate later:

- ComfyUI
- Diffusers

Candidate model families to evaluate later:

- Flux Schnell
- SDXL

These are not enabled in M26.0.

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

## Safety Gates

- No real generation in M26.0.
- No ComfyUI installation.
- No Blender installation.
- No Diffusers installation.
- No model downloads.
- No model file modifications.
- No GPU job execution.
- No arbitrary shell execution.
- No image output creation.

Real image generation requires a later explicit milestone, selected engine, selected model, runtime paths, safety checks, and tests.
