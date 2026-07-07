# Prompt Packs

Prompt packs are reusable source-text prompt notes for controlled image generation. They help operators start from known wording instead of inventing every prompt from scratch.

Prompt packs are source text only. They do not call ComfyUI, do not start services, and do not trigger generation automatically. Real image generation remains operator-controlled.

## What They Are NOT

- They are not generated images.
- They are not runtime output folders.
- They are not batch execution scripts.
- They are not construction documents or engineering proof.
- They are not permission to commit generated binaries.

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

## How To Use Prompt Packs

1. Pick the closest prompt pack and prompt section.
2. Replace placeholders such as `[SUBJECT]`, `[STRUCTURE]`, or `[ROOM_TYPE]`.
3. Copy the final prompt into a controlled generation command only after image mode has been prepared.
4. Record the exact final prompt, output path, seed, size, and review notes.

Prompt packs should make operator decisions easier, but the operator still decides when to generate, what settings to use, and whether the output is useful.

## Safety Rules

- Do not add automatic generation to prompt packs.
- Do not add uncontrolled batch execution.
- Do not use generated images as construction truth.
- Do not ask the model to produce exact readable text, labels, or dimensions inside the image.
- Use deterministic drawing tools for measured plans and geometry.

## Runtime Output Policy

Generated image files stay under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Prompt packs live in the repo because they are source text. Generated media does not live in the repo.

## Git Policy

Commit prompt pack text and documentation only. Do not commit PNG, JPG, JPEG, WEBP, model files, checkpoints, logs, pids, or runtime output.

## Visual References vs Technical Truth

Image prompts can produce useful visual references: mood, material direction, rough layout, lighting, and concept intent.

They cannot prove dimensions, structural safety, drainage, fastening strength, code compliance, or build sequencing. Technical truth must come from deterministic drawings, measured specs, engineering review, and operator validation.
