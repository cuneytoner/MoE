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

M26.2 adds an explicit download script. It still defaults to dry-run:

```bash
make download-flux-schnell-models-plan
```

Actual download is opt-in and writes only under `/home/cuneyt/MoE_Models_Backup`:

```bash
make download-flux-schnell-models-apply
```

The download script uses the current Hugging Face CLI:

```bash
hf download black-forest-labs/FLUX.1-schnell flux1-schnell.safetensors --local-dir /home/cuneyt/MoE_Models_Backup/flux
```

Do not use deprecated `huggingface-cli` commands.

`black-forest-labs/FLUX.1-schnell` may be gated. If access is denied, open:

```text
https://huggingface.co/black-forest-labs/FLUX.1-schnell
```

Accept or request access, then run:

```bash
hf auth login
```

Retry the download after approval.

The expected model paths are:

```text
/home/cuneyt/MoE_Models_Backup/flux/flux1-schnell.safetensors
/home/cuneyt/MoE_Models_Backup/vae/ae.safetensors
/home/cuneyt/MoE_Models_Backup/clip/clip_l.safetensors
/home/cuneyt/MoE_Models_Backup/clip/t5xxl_fp8_e4m3fn.safetensors
```

Validate the model set:

```bash
make check-flux-schnell-models
```

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
- Links `flux1-schnell.safetensors` to `ComfyUI/models/unet`.
- Links `ae.safetensors` to `ComfyUI/models/vae`.

## First Image Procedure

M26.2 adds the first guarded real image workflow. Generation is user-run only and requires `APPLY=1`.

Recommended sequence:

```bash
make runtime-mode-image-plan
make comfyui-vram-status
make download-flux-schnell-models-plan
make download-flux-schnell-models-apply
make check-flux-schnell-models
make link-comfyui-models-apply
make comfyui-up
make comfyui-flux-smoke-test
make comfyui-first-image-plan
make comfyui-first-image-apply
```

Default first prompt:

```text
realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
```

Default first test size:

```text
512x512, 4 steps
```

Outputs must stay under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

ComfyUI may initially save generated files under its own output directory:

```text
/home/cuneyt/MoE/runtime/media-engines/comfyui/ComfyUI/output
```

After workflow submission, `scripts/comfyui-first-image.sh` polls both the ComfyUI output directory and the project media output directory for new image files. It uses a unique `moe_flux_first_YYYYMMDD_HHMMSS` filename prefix and varies the default seed on each run so repeated runs are more likely to produce a fresh output. It then copies any new images into:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

The original ComfyUI output is not deleted.

Repeated ComfyUI runs may hit cache or complete without writing a new file, especially when the workflow inputs are unchanged. If no new image is detected but `flux-first` already contains images, the script prints a warning and lists the latest existing images. Set `STRICT_NEW_OUTPUT=1` to require a truly new image and fail otherwise:

```bash
STRICT_NEW_OUTPUT=1 make comfyui-first-image-apply
```

The first-image script writes its generated workflow JSON under:

```text
/home/cuneyt/MoE/runtime/media/workflows
```

No generated image or workflow output belongs in the source repository.

## VRAM Notes

Flux may need most of the PC-1 GPU. The image mode plan recommends stopping `llama-server` for VRAM before generation.

Check VRAM:

```bash
make comfyui-vram-status
```

This command prints `nvidia-smi` and warns if `llama-server` appears to be running. It does not kill or stop anything.

PC-2 does not generate images. PC-2 Prompt Interpreter only prepares dry-run job specs.

## Media API Bridge

Milestone 26.3 adds a Media API to Media Worker to ComfyUI bridge for image jobs.

Dry-run jobs are always allowed. Real jobs require `MEDIA_REAL_GENERATION_ENABLED=true` on Media API and Media Worker.

Real image job outputs are surfaced under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>
```

The real-run helper prints VRAM status and does not stop `llama-server` automatically.

When running Media API and Media Worker in Docker, the bridge uses Docker-safe addresses:

- Media API to Media Worker: `http://media-worker:8310`
- Media Worker to host ComfyUI: `http://host.docker.internal:8188`

On Linux, the Compose media services define `host.docker.internal:host-gateway` so containers can reach the host ComfyUI process.

## Gateway Guarded Integration

Milestone 26.4 lets Gateway plan media prompts and create Media API dry-run jobs:

```bash
make gateway-media-plan
make gateway-media-dry-run
make gateway-media-real-plan
```

`gateway-media-real-plan` demonstrates the default rejection path. Gateway does not generate by default and does not start ComfyUI or Docker containers.

Manual real generation through Gateway requires this sequence:

1. Use image runtime mode planning.
2. Start ComfyUI in bridge mode with `COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up`.
3. Start Media API and Media Worker with `MEDIA_REAL_GENERATION_ENABLED=true`.
4. Start Gateway with `GATEWAY_MEDIA_REAL_ALLOWED=true`.
5. Send `confirm_real_generation=true` to `/gateway/media/jobs/real`.

Media API and Media Worker still own job storage and ComfyUI processing. Outputs remain under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

## Media Dashboard

Milestone 26.5 adds a read-only image status view through Gateway:

```bash
make media-dashboard-status
make media-dashboard-open
```

The dashboard lists the latest image output paths from:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

It also shows service reachability and generation gates. It does not start ComfyUI, enable real generation, run Docker, or create image files.

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
- M26.2 real generation is opt-in only through `APPLY=1`.
- ComfyUI installation only through explicit optional user-run runtime script.
- No Blender installation.
- No Diffusers installation.
- Model downloads only through explicit optional user-run `APPLY=1` script.
- No model file modifications.
- GPU job execution only through explicit optional user-run `APPLY=1` first-image script.
- No arbitrary shell execution.
- No image output creation in the source repository.

Future real image generation requires all safety variables to be explicitly enabled:

```text
MEDIA_REAL_GENERATION_ENABLED=false
MEDIA_IMAGE_ENGINE=disabled
MEDIA_COMFYUI_URL=http://127.0.0.1:8188
MEDIA_ALLOW_GPU_JOBS=false
```

M26.2 real generation should only proceed when the `image` mode plan is explicit, ComfyUI is healthy, model components are validated, and the user has set `APPLY=1`.
