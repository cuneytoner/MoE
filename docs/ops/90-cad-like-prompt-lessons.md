# 90 CAD-like Prompt Lessons

This note summarizes the prompt strategy after the simplified technical drawing run.

## Lessons

- Flux often ignores exact technical drawing intent.
- `No perspective` is not always enough.
- Text labels and dimensions are unreliable.
- A better strategy is to generate geometry-only diagrams and add labels manually later.
- Avoid asking for multiple views in one image.
- Avoid asking for exact dimensions inside the image.
- Use one view per image.
- Use orthographic / flat vector / geometry-only language.
- Keep prompt shorter and stricter.

## Stronger Prompt Terms

Use:

- `orthographic`
- `flat vector diagram`
- `geometry only`
- `no text`
- `no labels`
- `no perspective`
- `no 3D`
- `no shading`
- `no wood texture`
- `white background`
- `simple black lines only`

## Prompt Shape

Prefer prompts that ask for:

- one view
- one object or connection
- no labels
- no numbers
- no dimensions
- simple black line geometry

Add labels and dimensions manually after generation.
