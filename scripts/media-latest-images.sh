#!/usr/bin/env bash
set -euo pipefail

IMAGE_DIR="${MEDIA_IMAGE_OUTPUT_DIR:-/home/cuneyt/MoE/runtime/media/outputs/images}"

echo "Latest media images"
echo "  image dir: $IMAGE_DIR"

if [ ! -d "$IMAGE_DIR" ]; then
  echo "WARN: image output directory does not exist."
  exit 0
fi

find "$IMAGE_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 20 | sed 's/^[^ ]* //'
