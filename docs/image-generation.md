# Image Generation Service Preparation

Milestone 26.0 prepares image generation without enabling real generation. Milestone 26.1-pre selects the planned engine path and adds read-only runtime/model probes. Milestone 26.1 prepares manual ComfyUI runtime activation and Flux Schnell model acquisition planning.

These milestones still do not run image generation, download models, call GPU jobs, call model runtime, or create image files. ComfyUI installation is available only through an explicit optional user-run command and writes only under `/home/cuneyt/MoE/runtime/media-engines/comfyui`.

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

## ComfyUI Runtime Activation Plan

Milestone 26.1 adds optional scripts for a manual ComfyUI runtime install under:

```text
/home/cuneyt/MoE/runtime/media-engines/comfyui
```

The installer uses the official ComfyUI repository:

```text
https://github.com/comfy-org/comfyui
```

It must be user-run and is not part of default tests:

```bash
make install-comfyui-runtime
make check-comfyui-runtime
```

The installer:

- Clones ComfyUI only if the runtime checkout is missing.
- Creates the Python virtualenv only under `/home/cuneyt/MoE/runtime/media-engines/comfyui/venv`.
- Installs Python dependencies into that runtime virtualenv.
- Prints `nvidia-smi` when available.
- Does not download models.
- Does not start ComfyUI.
- Does not write into the source repository.

Start and stop are manual:

```bash
make comfyui-up
make comfyui-health
make comfyui-down
```

ComfyUI binds to `127.0.0.1:8188` by default and is not exposed to the LAN in this milestone. Logs and PID files stay under the runtime engine directory.

## Flux Schnell Components

Current known local components:

```text
/home/cuneyt/MoE_Models_Backup/clip_l.safetensors
/home/cuneyt/MoE_Models_Backup/t5xxl_fp8_e4m3fn.safetensors
```

Still missing before real generation:

- Main Flux Schnell model.
- VAE/AE component.

Inspect the Flux-specific plan:

```bash
make plan-flux-schnell-models
```

The script prints recommended future target paths only:

```text
/home/cuneyt/MoE_Models_Backup/flux/flux1-schnell.safetensors
/home/cuneyt/MoE_Models_Backup/clip/clip_l.safetensors
/home/cuneyt/MoE_Models_Backup/clip/t5xxl_fp8_e4m3fn.safetensors
/home/cuneyt/MoE_Models_Backup/vae/ae.safetensors
```

Download commands are printed as comments only. No model is downloaded in M26.1.

## ComfyUI Model Links

Models remain stored under:

```text
/home/cuneyt/MoE_Models_Backup
```

ComfyUI should see models through symlinks only:

```bash
make link-comfyui-models-dry-run
make link-comfyui-models-apply
```

The link script:

- Defaults to dry-run.
- Creates symlinks only with `APPLY=1`.
- Never copies model files.
- Never deletes existing files.
- Skips existing targets safely.
- Links `clip_l.safetensors` to `ComfyUI/models/clip`.
- Links `t5xxl_fp8_e4m3fn.safetensors` to `ComfyUI/models/text_encoders`.
- Links a future Flux Schnell model to `ComfyUI/models/unet`.
- Links a future VAE/AE to `ComfyUI/models/vae`.

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

- No real generation in M26.0, M26.1-pre, or M26.1.
- ComfyUI installation only through explicit optional user-run runtime script.
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

Real generation must remain rejected until Milestone 26.2 explicitly sets the engine, validates model inventory, confirms runtime layout, and adds tests.

M26.2 must also wait for Control Plane mode gates from Milestone 26.1.5. Image generation should only proceed when the `image` mode plan is explicit, ComfyUI is healthy, model components are validated, and real generation safety variables are enabled.
