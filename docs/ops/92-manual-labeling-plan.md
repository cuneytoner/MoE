# 92 Manual Labeling Plan

Labels should be added manually after image generation.

Manual labeling may still be useful for image references, but real measured labels should come from deterministic SVG drawing.

## Why Manual Labels Are Better

- AI-generated text is often garbled.
- AI-generated dimensions are not reliable.
- Manual labels can match measured site values.
- Manual labels can be corrected without regenerating the image.
- Manual annotation keeps the generated diagram as geometry-only visual support.

## Suggested Manual Labels

- `10x10 post`
- `5x10 beam`
- `5x10 rafter`
- `polycarbonate roof`
- `roof overhang 30 cm`
- `depth 1.90 m`
- `wall line 5.10 m`
- `bracket`
- `bolt/washer`
- `post base`

## Tools That Can Be Used Later

- LibreOffice Draw
- Inkscape
- GIMP
- simple PDF annotation

## Git Safety

Do not commit generated binary images to Git.

Store generated or manually labeled images under runtime or an external archive.

Commit only notes, prompt text, and references to runtime paths.
