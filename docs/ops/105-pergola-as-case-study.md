# 105 Pergola As Case Study

The pergola was used as a real-world test object.

It had real dimensions, material constraints, image needs, and drawing needs.

## Why Pergola Was Useful

The pergola helped test:

- ComfyUI / Flux generation
- prompt variants
- VRAM safety
- runtime output handling
- dashboard `latest_images`
- reference-board docs
- deterministic SVG transition

## What Remains Useful

Pergola-specific work remains useful because it records a concrete end-to-end workflow:

- real prompt attempts
- generated output paths
- visual selection notes
- technical drawing limits
- deterministic SVG prototype
- usta/carpenter communication notes

## Broader Platform Goal

The platform goal is broader than pergola:

- generic image generation
- architectural concept generation
- deterministic drawing generation
- reusable media pipeline

Pergola prompts should later be migrated or referenced as a case-study prompt pack, but not during M34.1.

## Warning

Do not overfit the whole project to pergola.

Treat pergola as the first case study and prototype, not the final product scope.
