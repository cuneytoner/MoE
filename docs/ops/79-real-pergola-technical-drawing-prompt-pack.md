# 79 Real Pergola Technical Drawing Prompt Pack

This prompt pack prepares technical drawing-style prompts for the real pergola project.

AI-generated drawings are visual communication and planning support only. They are not engineering drawings, static calculations, or validated construction plans.

## What This Prompt Pack Is For

- Prepare measured carpenter-style drawing prompts.
- Cover elevation, plan, connection, roof sheet, drilling, and fastener views.
- Help communicate the intended structure to an usta/carpenter.
- Keep drawing-like outputs separate from real structural decisions.
- Prepare a future controlled drawing run without triggering generation.

## What This Prompt Pack Does NOT Do

- It does not run image generation.
- It does not create runtime files.
- It does not validate structure.
- It does not choose final post spacing, beam spans, fastener sizes, or roof slope.
- It does not replace real measurements, material checks, load-path review, or practical build review.
- It does not create automatic generation or batch execution.

## Real Project Assumptions

- DIY wooden pergola.
- Pine timber.
- Available timber sizes:
  - `10x10 cm` posts
  - `5x10 cm` beams/rafters
  - `5x5 cm` support pieces
  - `2.5x5 cm` small support/lath pieces
- Wall-side total width around `5.10 m`.
- Main depth around `1.90 m`.
- Roof overhang around `30 cm`.
- Fully covered roof for sun and rain protection.
- Translucent/polycarbonate roof panels are acceptable.
- Lean-to wall-side structure near house wall.
- Self-supported posts, not relying on wall load.
- Right-side door canopy/extension.
- Left side optional half-height protection around `70-90 cm`.
- Practical backyard construction, not luxury/resort.

## Drawing Types Needed

- front elevation
- side elevation
- top/plan view
- exploded connection detail
- beam-post connection detail
- post base detail
- roof sheet fastening detail
- drilling/fastener layout
- usta briefing sheet

## Prompt Design Principles For Technical Drawings

- Ask for `clean black line drawing on white background`.
- Include exact measurements where known.
- Use `carpenter technical drawing`, `practical usta plan`, or `construction detail`.
- Keep the prompt focused on one drawing type at a time.
- Mention `labels` and `dimension labels`.
- Mention timber sizes explicitly.
- Ask for plausible details, then review them critically.
- Prefer simple, readable drawings over artistic renderings.

## What To Avoid

- photorealistic render unless the prompt is explicitly a visual reference
- luxury architectural presentation
- fantasy structures
- oversized palace beams
- unsupported floating members
- vague connection details
- hidden fasteners
- decorative-only pergolas
- exact-looking dimensions that have not been checked

## Recommended Drawing Prompt Set

Start with the measured views:

- V1 Front elevation
- V2 Side elevation
- V3 Top plan view
- V4 Combined usta sheet

Then run connection/details only if the measured views are useful:

- C1 Beam-post connection
- C2 Post base
- C3 Roof sheet fastening
- D1 Beam bracket hole layout
- D2 Roof screw pattern

Prompt text is stored in:

- [80-pergola-measured-view-prompts.md](80-pergola-measured-view-prompts.md)
- [81-pergola-connection-detail-prompts.md](81-pergola-connection-detail-prompts.md)
- [82-pergola-fastener-and-drilling-prompt-pack.md](82-pergola-fastener-and-drilling-prompt-pack.md)

## Recommended Fixed Image Settings

Use fixed settings for comparison unless a future run plan changes them:

| Setting | Value |
| --- | --- |
| Width | `512` |
| Height | `512` |
| Steps | `4` |
| Seed | `1783334081` |

Run one prompt at a time in a future guarded milestone.

## How To Review Generated Drawing-Like Outputs

Use [83-pergola-technical-drawing-review-template.md](83-pergola-technical-drawing-review-template.md).

Check:

- whether the drawing type is recognizable
- whether dimensions are clear
- whether `10x10 cm` posts and `5x10 cm` beams/rafters are visible
- whether the roof is fully covered
- whether right-side door canopy/extension appears when relevant
- whether left half-height side protection appears when relevant
- whether connection details are plausible enough for discussion
- what is misleading or unsafe

## Safety Warning

AI-generated drawings are visual communication only.

Do not trust AI-generated dimensions, bracket geometry, load paths, post spacing, roof slope, fastener placement, or drilling layout without real review.

Real structural safety still requires material sizing, load paths, connection checks, weatherproofing details, drainage direction, and practical build review.
