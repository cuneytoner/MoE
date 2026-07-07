# Generic Image Generation Safety

## Core Rules

- Real generation is operator-controlled.
- No automatic generation.
- No uncontrolled batch.
- No overnight runs.
- No generated binaries in Git.
- No treating visuals as construction documents.

## Prompt Safety

- Avoid generated text inside images.
- Avoid exact dimensions in image prompt unless visual-only.
- Use deterministic drawing for measured plans.

## Output Safety

Generated image output belongs under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Only source text, prompt packs, templates, and documentation belong in the repo.

## Technical Truth

Generated images can communicate mood, materials, broad form, and visual intent. They must not be used as proof of structural safety, fastening details, drainage, measurements, code compliance, or construction sequencing.
