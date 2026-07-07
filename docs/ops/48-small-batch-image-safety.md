# 48 Small Batch Image Safety

A batch means more than one image request.

Small controlled batches can be useful, but they can also create unexpected GPU load, output clutter, and Git risk. Start small and stop early when anything looks wrong.

Before any controlled variant run, review [57-prompt-variant-stop-conditions.md](57-prompt-variant-stop-conditions.md).

## Batch Size

Start with 3 to 5 images only.

Do not run large batches until:

- Single-image generation is stable.
- Output naming is clear.
- Output review is comfortable.
- Git safety checks are routine.

Do not run an overnight batch yet.

## Fixed First Batch Settings

For the first prompt variant batch:

- Keep size at `512x512`.
- Keep steps low, such as `4`.
- Use the same seed for prompt comparison.
- Change prompt text only.
- Keep the same workflow JSON.

## Required Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make image-readiness
make comfyui-vram-status
make media-dashboard-status
git status --short
```

Expected good sign:

- Image readiness is green.
- VRAM status looks safe.
- Media dashboard is reachable.
- Git status does not show generated images or model files.

## Do Not Run Batch If

- llama-server is using VRAM.
- ComfyUI health is unstable.
- Output path is unclear.
- The batch has more than 5 images.
- The plan changes size, steps, seed, and prompt at the same time.
- The operator has not reviewed output naming.
- Git status shows generated image files.

## Stop Immediately If

- VRAM usage looks wrong.
- GPU temperature looks wrong.
- ComfyUI becomes unstable.
- No new image is detected.
- Images are written somewhere unexpected.
- Generated files appear inside the repo.

## Git Safety

Do not commit generated images.

Do not commit model files.

Do not copy outputs into:

```text
/home/cuneyt/DiskD/Projects/MoE/codebase
```

Generated outputs belong under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

## What Not To Do

- Do not add batch execution scripts yet.
- Do not remove real-generation guards.
- Do not make Gateway execute shell commands.
- Do not alter Docker Compose for a batch run.
- Do not use `docker volume prune`.
- Do not delete generated outputs as a default cleanup step.
