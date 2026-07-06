# 42 Flux Schnell Parameter Guide

This guide explains the important parameters from the first successful Flux Schnell image run.

It is for safe beginner edits and planning. It does not run generation by itself.

## First Successful Parameters

| Parameter | Current value | Safe change? | Notes |
| --- | --- | --- | --- |
| Prompt | `realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight` | Yes | Safest parameter to change first. It changes image content and style. |
| Width | `512` | Caution | Larger width uses more VRAM and may change runtime stability. |
| Height | `512` | Caution | Larger height uses more VRAM and may change runtime stability. |
| Steps | `4` | Caution | More steps may improve detail but takes longer and uses more GPU time. |
| Seed | `1783334081` | Yes | Same prompt and settings with same seed should be more reproducible. Changing it explores variants. |
| Filename prefix | `moe_flux_first_20260706_133441` | Yes | Use clear prefixes so outputs are easy to find later. |
| Output folder | `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first` | Caution | Keep outputs under runtime media folders, never inside the repo. |
| Strict new output flag | Enabled for first-run safety | Caution | Helps avoid confusing old outputs with new outputs. Keep it on unless a future runbook says otherwise. |

## Prompt

First successful prompt:

```text
realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
```

Changing the prompt changes the subject, materials, composition, and style.

Safe beginner prompt changes:

- Change one visual detail at a time.
- Keep the prompt short.
- Preserve the same size, steps, and workflow while testing prompt changes.
- Record the exact prompt in [43-comfyui-workflow-change-log.md](43-comfyui-workflow-change-log.md).

## Width And Height

First successful size:

```text
512x512
```

Changing width or height changes the image dimensions and VRAM pressure. For beginner tests, keep `512x512` until prompt and seed behavior are understood.

## Steps

First successful steps:

```text
4
```

Changing steps changes how much denoising work the model performs. More steps may improve detail, but can take longer. Very high values are not a beginner-safe first edit.

## Seed

First successful seed:

```text
1783334081
```

The seed controls the random starting point. Keep the seed fixed when testing prompt wording. Change the seed when exploring visual variants of the same prompt.

## Filename Prefix

First successful filename prefix:

```text
moe_flux_first_20260706_133441
```

The generated output example was:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

Use readable prefixes that include the purpose or date. Do not use repo paths as output prefixes.

## Output Folder

First successful output folder:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

Generated images must stay under runtime storage. Do not write image outputs into `/home/cuneyt/DiskD/Projects/MoE/codebase`.

## Strict New Output Flag

The first successful run used a strict new output expectation so the operator could tell whether the run created a fresh PNG.

Keep this behavior for beginner tests. It protects against mistaking an older image for a new successful generation.

## Safe Beginner Changes

Start with:

- Prompt wording
- Seed
- Filename prefix

Keep unchanged at first:

- Size
- Steps
- Workflow file path
- Model file paths
- Output root

## Risky Changes

Avoid these until a separate reviewed plan exists:

- Larger sizes such as `768x768` or `1024x1024`
- Large step increases
- Model file swaps
- Text encoder swaps
- VAE swaps
- Workflow node rewiring
- Output paths inside the repo
- Turning off safety gates that distinguish old outputs from new outputs

## Recommended Next Test Matrix

Use one variable at a time:

| Test | Prompt | Size | Steps | Seed | Goal |
| --- | --- | --- | --- | --- | --- |
| A | Same as first success | `512x512` | `4` | `1783334081` | Confirm reproducibility path. |
| B | Small prompt wording change | `512x512` | `4` | `1783334081` | See prompt effect with fixed seed. |
| C | Same prompt as B | `512x512` | `4` | New reviewed seed | Explore one visual variant. |
| D | Same prompt as B | `512x512` | `6` | Same as C | Compare a small step increase only after A through C are reviewed. |

Record every real run in [43-comfyui-workflow-change-log.md](43-comfyui-workflow-change-log.md). Do not commit generated image binaries.

## Prompt Variant Strategy

For first prompt variants:

- Keep size fixed at `512x512`.
- Keep steps fixed at `4`.
- Change prompt text only.
- Use a fixed seed for comparison.
- Later, change seed for exploration after prompt effects are understood.

For planned prompt variants and small batch comparisons, use [47-prompt-variants-plan.md](47-prompt-variants-plan.md), [48-small-batch-image-safety.md](48-small-batch-image-safety.md), [49-image-comparison-notes-template.md](49-image-comparison-notes-template.md), and [50-batch-output-naming-policy.md](50-batch-output-naming-policy.md).
