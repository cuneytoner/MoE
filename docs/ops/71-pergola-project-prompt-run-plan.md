# 71 Pergola Project Prompt Run Plan

This plan prepares the next controlled run using project-specific pergola prompts.

It does not include real generation commands yet.

Use [54-controlled-prompt-variant-generation.md](54-controlled-prompt-variant-generation.md) for the existing controlled generation guide when execution is intentionally started by the operator.

## Recommended First 3 Prompts

Run these first:

| Order | Prompt | Source |
| --- | --- | --- |
| 1 | P1 Project overview | [68-pergola-project-overview-prompts.md](68-pergola-project-overview-prompts.md) |
| 2 | P4 Rain protection | [68-pergola-project-overview-prompts.md](68-pergola-project-overview-prompts.md) |
| 3 | T1 Beam-post joint | [69-pergola-technical-detail-prompts.md](69-pergola-technical-detail-prompts.md) |

## Fixed Settings

| Setting | Value |
| --- | --- |
| Width | `512` |
| Height | `512` |
| Steps | `4` |
| Seed | `1783334081` |

## Operator Note

Run one prompt at a time.
Do not run an automatic batch.
Stop if free VRAM is too low or ComfyUI health fails.

## Evidence To Record

After each prompt, record:

- prompt ID
- full prompt text
- output path
- output filename
- file size
- dashboard status
- visual notes
- VRAM note
- shutdown result
- coding mode restore result
- Git safety result

Use [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md) for result notes.
