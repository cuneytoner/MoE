#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
OUTPUT_DIR="/home/cuneyt/MoE/runtime/media/outputs/images"

section() {
  echo ""
  echo "== $1 =="
}

cd "$CODEBASE_DIR"

section "Latest media images"
make media-latest-images

section "Latest image directories"
if [ -d "$OUTPUT_DIR" ]; then
  find "$OUTPUT_DIR" -mindepth 1 -maxdepth 2 -type d -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 20 | cut -d' ' -f2-
else
  echo "Output directory does not exist yet: $OUTPUT_DIR"
fi

if [ "${OPEN:-0}" = "1" ]; then
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$OUTPUT_DIR"
  else
    echo "WARN: xdg-open is not available"
  fi
fi
