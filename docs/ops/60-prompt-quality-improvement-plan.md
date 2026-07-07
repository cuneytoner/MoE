# 60 Prompt Quality Improvement Plan

This plan structures the next prompt improvement round after the first controlled 3-variant pergola run.

It is documentation-only. It does not run image generation.

Source review context: M32.2 was recorded at commit `05b56d4` (`docs: add prompt variant result review`).

The improved prompt run results are recorded in [64-improved-prompt-run-result-review.md](64-improved-prompt-run-result-review.md), and lessons learned are summarized in [65-pergola-prompt-lessons-learned.md](65-pergola-prompt-lessons-learned.md).

## What This Plan Is For

- Turn the first controlled results into better next prompts.
- Improve realistic pergola, rainy pergola, and technical construction/documentation outputs.
- Keep the next comparison run controlled and reviewable.
- Preserve fixed settings before changing seed, steps, or size.

## What This Plan Does NOT Do

- It does not run real image generation.
- It does not alter `scripts/comfyui-first-image.sh`.
- It does not alter Gateway behavior.
- It does not alter Docker Compose.
- It does not add automatic generation.
- It does not delete generated images.
- It does not create runtime files.

## Current Baseline Result

Output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_base_20260707_125339_00001_.png
```

Result: successful. Clean and visually coherent pergola/garden image.

Issue: good visual quality, but still too generic for a practical project reference.

## Current Rain Result

Output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_rain_20260707_125421_00001_.png
```

Result: successful. Rain intent appears, but the scene still looks too clean/dry.

Issue: needs stronger rain, overcast, wet material, and reflection language.

## Current Technical Result

Output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_technical_20260707_125431_00001_.png
```

Result: successful image, but not technical enough. It still looks like a polished photo/render.

Issue: needs visible joinery, construction details, unfinished work, measuring tools, and beam/post connection emphasis.

## What Worked

- `512x512`, `4` steps, and seed `1783334081` were stable enough for comparison.
- Three variants were manageable.
- Fixed settings made prompt differences easier to inspect.
- Safe shutdown restored coding mode after generation.

## What Did Not Work

- The rain prompt did not force enough wet surfaces or overcast atmosphere.
- The technical prompt did not force enough construction-documentation detail.
- The base prompt did not include enough practical project constraints.

## Prompt Improvement Principles

- Add concrete physical details instead of vague style words.
- For rain, name visible wet surfaces and sky conditions.
- For technical output, name hardware, joinery, tools, and unfinished construction state.
- Avoid luxury/resort/showroom language.
- Keep one comparison variable stable where possible.
- Do not change all variables at once.

## Summary Table

| Track | Current issue | Improvement direction |
| --- | --- | --- |
| Base | Good visual quality, but too generic | Add closer-to-project constraints |
| Rain | Not wet/overcast enough | Add wet floor, rain streaks, damp wood, cloudy sky |
| Technical | Too polished, not construction-documentation enough | Add visible joinery, bolts, beam labels, unfinished construction, measuring tape |

## Next Prompt Set

Use [61-next-pergola-prompt-set.md](61-next-pergola-prompt-set.md) for the next candidate prompts:

- Project-like covered pergola
- Rain protection pergola
- Technical construction documentation
- Usta / carpenter inspection photo
- Roof detail photo

## Fixed Settings For Next Run

Keep these fixed for the comparison run:

| Setting | Value |
| --- | --- |
| Width | `512` |
| Height | `512` |
| Steps | `4` |
| Seed | `1783334081` |
| Workflow | `/home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json` |

Try a second seed only after reviewing the fixed-seed comparison.

## What To Compare

For each output, compare:

- Pergola geometry
- Covered roof clarity
- Practical construction realism
- Rain/wetness visibility
- Joinery and hardware visibility
- Avoidance of luxury/render style
- Usefulness for a real project reference

Use [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md).

## Go / No-Go Checklist

Go only if:

- The next prompt set is reviewed.
- Fixed settings remain unchanged.
- Stop conditions are understood.
- Output naming is clear.
- Git safety check is clean.

No-go if:

- The operator wants to change prompt, seed, steps, and size together.
- ComfyUI or VRAM state is unclear.
- Output paths are unclear.
- Generated files appear inside the repo.

## Git Safety Reminder

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: generated images, model files, and checkpoints do not appear as tracked or staged repo files.
