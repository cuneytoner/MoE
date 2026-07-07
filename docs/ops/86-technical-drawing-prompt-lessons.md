# 86 Technical Drawing Prompt Lessons

This note summarizes lessons from the first technical drawing controlled run.

A stronger CAD-like geometry-only prompt strategy is documented in [90-cad-like-prompt-lessons.md](90-cad-like-prompt-lessons.md) and [91-next-cad-like-geometry-only-prompts.md](91-next-cad-like-geometry-only-prompts.md).

## Lessons

- Flux can produce technical-looking drawings.
- Text labels are often garbled.
- Dimension values are not reliable.
- Complex combined sheets are too much for one `512x512` image.
- Single-topic detail prompts work better than multi-view sheets.
- Close-up connection prompts are useful for intent but not structural plans.

## Next Prompt Rules

Next prompts should:

- use fewer labels
- request simple 2D black line schematic
- avoid many text annotations
- focus on one part at a time
- use `no text except simple labels A/B/C` if needed
- use `blank white background`
- avoid perspective when exact layout is needed

## Practical Guidance

Prefer:

- one view per image
- one connection per image
- one fastening pattern per image
- minimal labels
- schematic shapes over textured construction renderings

Avoid:

- combined sheets at `512x512`
- many dimension labels
- dense text callouts
- perspective views when checking layout
- treating generated labels as factual
