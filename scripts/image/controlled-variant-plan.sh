#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Controlled prompt variant plan (dry-run helper only)

This helper does not submit ComfyUI workflows.
This helper does not call real generation endpoints.
This helper does not write runtime files.

Fixed settings:
  width: 512
  height: 512
  steps: 4
  seed: 1783334081
  workflow: /home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json

Planned variants:
  A: Base pergola prompt, same seed
     realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
  B: Add "wide angle photo"
     realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight, wide angle photo
  C: Add "rainy weather"
     realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight, rainy weather
  D: Add "evening warm light"
     realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight, evening warm light
  E: Add "technical construction photo"
     realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight, technical construction photo

Safety reminder:
  - run image-readiness first
  - stop llama-server before real generation
  - do not commit generated outputs
  - run one variant at a time
  - do not use an automatic generation loop
EOF
