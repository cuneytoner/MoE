# Generic Prompt Pack Structure

## What Was Added

M34.1 adds a reusable prompt pack structure under `tools/prompt-packs`. These files are source text only. They help operators prepare prompts for controlled image generation without adding automatic generation or runtime output to the repo.

## Folder Structure

```text
tools/prompt-packs/
  README.md
  generic-image/
    README.md
    base-prompts.md
  architecture/
    README.md
    exterior-prompts.md
    interior-prompts.md
  technical-reference/
    README.md
    visual-reference-prompts.md
```

## Prompt Pack Categories

- `generic-image`: general object, concept, mood board, marketing, and before/after prompts.
- `architecture`: exterior, interior, outdoor structure, material, and lighting concept prompts.
- `technical-reference`: visual-only technical reference prompts for connections, assemblies, materials, safety, and schematic-looking concepts.

## How To Use Prompt Packs

1. Open the prompt pack closest to the task.
2. Copy one prompt section.
3. Replace placeholders such as `[SUBJECT]`, `[STRUCTURE]`, or `[ROOM_TYPE]`.
4. Use the final prompt only in an operator-controlled generation flow.
5. Record the exact final prompt, settings, output path, and review notes.

Example controlled generation command:

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase

PROMPT="realistic architectural exterior concept of a small garden studio, practical construction, natural daylight, realistic materials, human-scale proportions, clean composition" \
WIDTH=512 HEIGHT=512 STEPS=4 SEED=1783334081 \
FILENAME_PREFIX="generic_arch_exterior_$(date +%Y%m%d_%H%M%S)" \
APPLY=1 scripts/comfyui-first-image.sh
```

Do not run this command unless image mode has been prepared with `scripts/image/image-mode-prepare.sh`.

## What Not To Do

- Do not run image generation from this document during documentation work.
- Do not add generated images to the repo.
- Do not add automatic generation to prompt packs.
- Do not use prompt packs as batch runners.
- Do not treat visual references as measured construction documents.

## Safety Rules

- Real image generation remains operator-controlled.
- Avoid exact text, labels, and dimensions inside generated images.
- Prefer deterministic drawing tools for plans, elevations, dimensions, and geometry.
- Review outputs manually before reusing a prompt as a preset.

## Runtime Output Policy

Generated image output belongs under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

The repo stores prompt text and documentation only.

## Next Steps

- Use the review template in [110-prompt-pack-review-template.md](110-prompt-pack-review-template.md).
- Keep safety guidance aligned with [111-generic-image-generation-safety.md](111-generic-image-generation-safety.md).
- Later, decide which successful prompt patterns should become formal presets.
