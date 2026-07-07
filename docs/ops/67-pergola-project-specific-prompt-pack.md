# 67 Pergola Project-Specific Prompt Pack

This prompt pack turns the successful generic pergola prompts into prompts closer to the real planned DIY structure.

## What This Prompt Pack Is For

- Capture the real pergola constraints in reusable prompt language.
- Keep future image runs focused on the actual wall-side, narrow-garden structure.
- Separate overview, detail, rain, and side-extension prompt directions.
- Prepare the next controlled run without triggering generation.

## What This Prompt Pack Does NOT Do

- It does not run image generation.
- It does not define automatic batches.
- It does not change ComfyUI workflows.
- It does not alter Gateway runtime behavior.
- It does not alter Docker Compose.
- It does not write runtime files.

## Real Project Constraints Summary

- DIY wooden pergola.
- Pine wood.
- Available lumber sizes:
  - `10x10 cm` posts
  - `5x10 cm` beams and rafters
  - `5x5 cm` and `2.5x5 cm` smaller support pieces if needed
- Approximate wall line width:
  - main plus right extension around `5.10 m` total
- Main depth:
  - around `1.90 m`
- Roof overhang:
  - about `30 cm`
- Roof:
  - fully covered roof for sun and rain protection
  - translucent or polycarbonate roof panels are acceptable visual language
- Structure:
  - lean-to style near house wall
  - self-supported with posts
  - practical backyard construction, not luxury or resort style
- Design intent:
  - narrow garden or wall-side walkway feel
  - rain protection
  - sun shading
  - visible timber frame
  - visible joinery
  - metal brackets, screws, and bolts where useful
- Extra feature:
  - right-side door canopy or extension area
  - left side may be semi-closed or have half-height side protection

## Prompt Design Principles

- Put dimensions in the prompt when testing overview prompts.
- Use `lean-to`, `wall-side`, `narrow garden`, and `walkway` to keep the structure grounded.
- Use `self-supported posts` when the image should not rely only on wall attachment.
- Keep `fully covered translucent polycarbonate roof panels` for covered-roof clarity.
- Use exact lumber sizes for technical prompts.
- Ask for practical construction and documentary style rather than polished architectural render.
- Include fasteners and brackets only when they should be visible.

## Fixed Visual Constraints

- Natural pine timber.
- `10x10 cm` posts.
- `5x10 cm` beams and rafters.
- Fully covered roof.
- Translucent or polycarbonate roof panels.
- Narrow wall-side garden or walkway.
- Practical DIY construction.
- Visible timber frame.
- No luxury resort styling.

## What To Avoid

- Open-roof decorative pergolas.
- Huge garden pavilions.
- Tropical villa or resort language.
- Glossy showroom render style.
- Metal-only or concrete-only structures.
- Impossible floating beams.
- Oversized palace-scale timber.
- Images with no visible construction details.

## Recommended First 5 Prompts

| Prompt ID | Purpose | Key constraints |
| --- | --- | --- |
| P1 | project overview | 5.1m wall line, 1.9m depth, covered roof |
| P2 | wall-side lean-to | brick wall, narrow garden, self-supported posts |
| P3 | rain protection | wet floor, covered polycarbonate roof |
| P4 | technical frame | 10x10 posts, 5x10 beams, brackets |
| P5 | side/door canopy | right-side small canopy extension |

Use [68-pergola-project-overview-prompts.md](68-pergola-project-overview-prompts.md) for the exact prompt text.

Note: the execution prompt list uses P4 for the rain protection overview prompt. Technical frame prompts are expanded as T1 through T5 in [69-pergola-technical-detail-prompts.md](69-pergola-technical-detail-prompts.md).

## Recommended Technical/Detail Prompts

Use [69-pergola-technical-detail-prompts.md](69-pergola-technical-detail-prompts.md).

Start with:

- T1 beam-post joint
- T2 roof sheet fastening
- T3 post base

These prompts should focus on close-up construction evidence: screw heads, washers, metal brackets, anchor bolts, pencil marks, and unfinished pine.

## Recommended Rain/Sun Protection Prompts

For rain and sun protection, emphasize:

- fully covered translucent roof panels
- wet stone walkway
- damp pine wood
- visible rain streaks
- realistic reflections
- shade under roof panels
- walking path protected by the roof

P3 and P4 in [68-pergola-project-overview-prompts.md](68-pergola-project-overview-prompts.md) are the first candidates.

## Recommended Comparison Settings

Use fixed settings until a future review changes them:

| Setting | Value |
| --- | --- |
| Width | `512` |
| Height | `512` |
| Steps | `4` |
| Seed | `1783334081` |

Run one prompt at a time.

Do not run an automatic batch.

## How To Record Results

Record each future result in:

- [53-media-dashboard-review-template.md](53-media-dashboard-review-template.md)
- [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md)

Record:

- prompt ID
- full prompt text
- workflow
- size
- steps
- seed
- output path
- output filename
- file size
- dashboard visibility
- Git safety result
- visual notes
- whether ComfyUI was stopped
- whether coding mode was restored
