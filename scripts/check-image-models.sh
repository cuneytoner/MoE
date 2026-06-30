#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"

echo "Checking image model inventory placeholders"
echo "  model backup dir: ${MODEL_BACKUP_DIR}"

if [ ! -d "$MODEL_BACKUP_DIR" ]; then
  echo "WARN: model backup directory does not exist: ${MODEL_BACKUP_DIR}"
  echo "WARN: M26.0 does not require image models; M26.1 will require selecting an engine/model."
  exit 0
fi

matches="$(find "$MODEL_BACKUP_DIR" -maxdepth 3 \( \
  -iname "*flux*" -o \
  -iname "*sdxl*" -o \
  -iname "*stable*" -o \
  -iname "*diffusion*" -o \
  -iname "*.safetensors" -o \
  -iname "*.ckpt" \
\) -print 2>/dev/null | sort || true)"

if [ -n "$matches" ]; then
  echo "PASS: possible image or media model candidates found:"
  printf '%s\n' "$matches"
else
  echo "WARN: no likely image model files found yet."
fi

echo "INFO: M26.1-pre is decision/probe-only and does not require an image model."
echo "INFO: Use scripts/plan-image-model-downloads.sh for component-level planning without downloads."
