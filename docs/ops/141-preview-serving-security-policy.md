# Preview Serving Security Policy

## Purpose

Preview serving must help operators inspect known output cards without exposing arbitrary files.

## Explicit Deny

- no arbitrary absolute paths
- no `..` traversal
- no symlinks outside allowlisted roots
- no hidden files
- no hidden folders
- no model files
- no `.gguf`
- no `.safetensors`
- no `.pt`
- no `.pth`
- no `.ckpt`
- no shell execution
- no generation trigger
- no delete/move/rename

## Allowed Extensions

Only these preview extensions should be allowed at first:

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`

The initial M34.13 implementation serves only raster image formats and blocks SVG.

Maybe later, after sanitization policy:

- `.svg`

## Allowlisted Roots

Preview serving must reuse output-card allowlisted runtime folders. A preview request should resolve to a known output card before any bytes are served.

## SVG Handling

SVG can contain active content in some contexts. Treat SVG preview carefully.

The initial implementation may show an SVG placeholder only. Direct SVG serving should wait until the project has an explicit sanitization and content-security policy.

## Model File Safety

Preview serving must never expose model files or model backup folders.

Blocked model extensions include:

- `.gguf`
- `.safetensors`
- `.pt`
- `.pth`
- `.ckpt`

## Operational Safety

Preview serving is read-only. It must not mutate assets, create derived files, delete files, move files, rename files, start services, stop services, or trigger media generation.
