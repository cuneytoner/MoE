# 47 Prompt Variants Plan

This guide explains how to plan prompt variants before generating multiple images.

It prepares small, controlled future tests without enabling uncontrolled generation.

For the operator-controlled execution guide, use [54-controlled-prompt-variant-generation.md](54-controlled-prompt-variant-generation.md).

## What This Guide Is For

- Plan prompt variants before running image generation.
- Keep tests beginner-friendly and reviewable.
- Change only one variable at a time.
- Keep size, steps, seed, workflow, and output rules clear.
- Record results without committing generated image binaries.

## What This Guide Does NOT Do

- It does not run real image generation.
- It does not add batch execution scripts.
- It does not add automatic generation.
- It does not make Gateway execute shell commands.
- It does not edit workflow JSON.
- It does not alter Docker Compose.
- It does not delete generated images.

## Base Prompt

Known successful prompt:

```text
realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
```

Known first image settings:

| Setting | Value |
| --- | --- |
| Size | `512x512` |
| Steps | `4` |
| Seed | `1783334081` |
| Workflow JSON | `/home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json` |

Known successful output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

## Why Only One Variable Should Change At A Time

When only one prompt phrase changes, the result is easier to understand.

For example, if the seed, size, steps, and prompt all change at once, it is hard to tell whether the improvement came from the prompt or from another setting. For first tests, change prompt text only.

## Safe First Variant Set

| Variant | Prompt change | Size | Steps | Seed | Purpose |
| --- | --- | --- | --- | --- | --- |
| A | Base pergola prompt, same seed | `512x512` | `4` | `1783334081` | Confirm baseline behavior |
| B | Add `wide angle photo` | `512x512` | `4` | `1783334081` | Test camera framing |
| C | Add `rainy weather` | `512x512` | `4` | `1783334081` | Test weather change |
| D | Add `evening warm light` | `512x512` | `4` | `1783334081` | Test lighting change |
| E | Add `technical construction photo` | `512x512` | `4` | `1783334081` | Test documentation-style output |

## What To Keep Fixed

Keep these fixed for the first variant set:

- Size: `512x512`
- Steps: `4`
- Seed: `1783334081`
- Workflow JSON path
- Model files
- Output root under `/home/cuneyt/MoE/runtime/media/outputs/images`

## What To Change

Change only the prompt text. For the first variant set, add one short phrase to the base prompt.

Do not change:

- Model files
- Workflow node structure
- Docker Compose
- Gateway behavior
- Runtime output path policy

## How To Record Results

For each future generated image, record:

- Variant letter
- Full prompt
- Size
- Steps
- Seed
- Output filename
- Output path
- Visual notes
- Keep or reject decision
- Git safety result

Use [49-image-comparison-notes-template.md](49-image-comparison-notes-template.md).

For future variants, dashboard `latest_images` can help locate the newest output, but comparison notes should still record the path and prompt manually.

After the first variant run, prompt improvements are tracked in [60-prompt-quality-improvement-plan.md](60-prompt-quality-improvement-plan.md), [61-next-pergola-prompt-set.md](61-next-pergola-prompt-set.md), [62-negative-prompt-notes.md](62-negative-prompt-notes.md), and [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md).

## Go / No-Go Before Batch Generation

Go only if:

- The batch has 3 to 5 planned images.
- Size remains `512x512`.
- Steps remain low, such as `4`.
- ComfyUI health is stable.
- VRAM looks safe.
- Output path is clear.
- Git status does not show generated images or model files.

No-go if:

- llama-server is still using VRAM.
- ComfyUI health is unstable.
- Output path is unclear.
- The plan changes multiple variables at once.
- The operator cannot explain where outputs will be stored.

Read [48-small-batch-image-safety.md](48-small-batch-image-safety.md) before any future batch run.

## Git Safety Reminder

Generated images and model files must stay out of Git.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: generated image binaries and model files do not appear as tracked or staged repo files.
