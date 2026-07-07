# 58 Prompt Variant Result Review

This review records the first controlled prompt variant generation results.

The real controlled 3-variant run was executed manually by the operator. Generated outputs stayed under runtime media storage and were not deleted.

## What This Review Is For

- Record the first controlled prompt variant outputs.
- Capture output paths and file sizes.
- Record runtime and shutdown observations.
- Preserve Git safety evidence without committing binaries.
- Collect lessons for the next prompt quality pass.

## What This Review Does NOT Do

- It does not run image generation.
- It does not delete generated outputs.
- It does not edit workflow JSON.
- It does not alter Gateway behavior.
- It does not alter Docker Compose.
- It does not add automatic generation.

## Run Summary

The controlled run generated 3 prompt variants:

- Base
- Rain
- Technical

Observed run state:

- ComfyUI was reachable during generation.
- Media API and Media Worker were OK.
- PC-2 Prompt Interpreter was OK.
- llama-server was stopped during image mode.
- VRAM became low during ComfyUI generation because Flux loaded around 13.9 GB, but generation succeeded.
- Safe shutdown stopped ComfyUI.
- Safe shutdown restarted `qwen-coder-14b-fast`.
- Gateway health after restore returned `model_runtime` ok.
- Generated images stayed under `/home/cuneyt/MoE/runtime/media/outputs/images`.

## Variant Table

| Variant | Prompt change | Output filename | Size bytes | Result |
| --- | --- | --- | ---: | --- |
| Base | none | `moe_pergola_base_20260707_125339_00001_.png` | 538673 | success |
| Rain | rainy weather | `moe_pergola_rain_20260707_125421_00001_.png` | 524667 | success |
| Technical | technical construction photo | `moe_pergola_technical_20260707_125431_00001_.png` | 543507 | success |

## Output Paths

Base:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_base_20260707_125339_00001_.png
```

Rain:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_rain_20260707_125421_00001_.png
```

Technical:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_technical_20260707_125431_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| Base | 538673 |
| Rain | 524667 |
| Technical | 543507 |

## Visual Notes Placeholder

```text
Base visual notes:
Rain visual notes:
Technical visual notes:

Best overall:
Best for construction/reference use:
Best next prompt direction:
Reject/avoid notes:
```

## VRAM Notes

Flux loaded around 13.9 GB and VRAM became low during generation.

Lesson: keep first controlled batches small, run one variant at a time, and continue checking VRAM before expanding prompt variant work.

## Safe Shutdown Result

Safe shutdown succeeded:

- ComfyUI was stopped.
- Generated outputs were not deleted.
- Image mode ended cleanly.

## Coding Mode Restore Result

Coding mode was restored:

- `qwen-coder-14b-fast` restarted.
- Gateway health after restore reported `model_runtime` ok.

## Dashboard Result

Use [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) and [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) to review whether `latest_images` surfaces these outputs.

Dashboard output review should remain read-only.

## Git Safety Result

Generated images stayed under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Use the extension-anchored Git binary check:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: no tracked generated images or model files are listed.

## Lessons Learned

- Three variants is a good first controlled run size.
- Fixed size, steps, and seed made comparison easier.
- VRAM can become low even when generation succeeds.
- Safe shutdown and coding-mode restoration should remain part of every real run.
- Git binary checks should use extension-anchored patterns to avoid false positives from words like `prompt`.

## Next Prompt Ideas

- Compare `wide angle photo` against the base prompt.
- Compare `evening warm light` against the base prompt.
- Try a construction-focused prompt with clearer material and joinery details.
- Keep `512x512`, `4` steps, and one variant at a time until review habits are stable.

For the next improvement round, use:

- [60-prompt-quality-improvement-plan.md](60-prompt-quality-improvement-plan.md)
- [61-next-pergola-prompt-set.md](61-next-pergola-prompt-set.md)
- [62-negative-prompt-notes.md](62-negative-prompt-notes.md)
- [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md)
