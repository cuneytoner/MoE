# 104 Generic Image + Architecture Drawing Roadmap

This roadmap reframes the pergola work as the first case study for a broader media and drawing pipeline.

## Why This Roadmap Exists

The pergola exploration proved useful system behavior across real image generation, prompt review, reference-board handling, and deterministic drawing generation.

The project should now generalize those lessons instead of overfitting the platform around one pergola.

## What Pergola Proved

- Flux/ComfyUI can generate useful realistic concept images.
- Prompt variants help compare visual direction.
- Reference-board notes are useful for selecting intent images.
- Dashboard `latest_images` can support output review.
- Runtime media storage keeps generated files outside Git.
- Deterministic SVG is better than Flux for measured drawings.
- Real-world constraints make the pipeline easier to validate.

## What Pergola Did NOT Solve

- Generic prompt pack organization.
- Generic architecture/concept image categories.
- Reusable drawing-engine structure.
- Generic media dashboard output cards.
- Multi-project asset library behavior.
- Safe metadata capture for prompts and generated outputs.
- Final PDF/DXF drawing export.

## Track A: Generic Image Generation

Track A covers reusable image generation workflow:

- prompt packs
- controlled single-image runs
- small prompt variants
- real generation guardrails
- image output review
- output naming policy

This track should stay operator-controlled. Real generation should not become automatic or uncontrolled.

## Track B: Architecture / Concept Image Generation

Track B covers visual concept work:

- architecture exterior concepts
- interior concepts
- garden/pergola/structure concepts
- rain/sun/material variants
- client/usta visual communication

Flux/ComfyUI is useful here because visual mood, material, weather, lighting, and intent are more important than exact dimensions.

## Track C: Deterministic Drawing Engine

Track C covers measured technical drawings:

- SVG first
- PDF later
- DXF later
- deterministic labels
- measured geometry
- drawing templates
- generic drawing-engine folder later

AI-generated images should not be used as source-of-truth technical drawings.

## Track D: Media Dashboard / Asset Library

Track D covers output review and browsing:

- latest images
- output cards
- metadata
- prompt text
- file path
- size
- reference-board selection

The dashboard should remain read-only unless a future milestone explicitly designs safe write behavior.

## Track E: Reference-board Workflow

Track E covers human selection:

- select useful images
- classify image purpose
- mark "visual only"
- never treat AI output as engineering truth

Reference boards should record paths, prompts, categories, and notes without committing generated binaries.

## What Stays Pergola-specific For Now

- `tools/pergola-drawings`
- pergola prompt lessons
- pergola reference board
- pergola SVG outputs under runtime
- pergola geometry assumptions
- usta/carpenter briefing notes

## What Becomes Generic Later

- prompt pack folder structure
- drawing-engine helper modules
- dashboard output card schema
- asset/reference-board metadata
- SVG/PDF/DXF generation patterns
- review templates for image and drawing outputs

M34.1 creates the generic prompt pack structure under `tools/prompt-packs`.

## Next Milestone Sequence

- M34.1 Generic Prompt Pack Structure
- M34.2 Generic Drawing Engine Skeleton
- M34.3 Media Dashboard Output Cards
- Later: generic reference-board metadata
- Later: PDF/DXF export planning
