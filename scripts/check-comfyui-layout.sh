#!/usr/bin/env bash
set -euo pipefail

COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
CREATE="${CREATE:-0}"

planned_dirs=(
  "$COMFYUI_RUNTIME_DIR"
  "$COMFYUI_RUNTIME_DIR/ComfyUI"
  "$COMFYUI_RUNTIME_DIR/venv"
  "$COMFYUI_RUNTIME_DIR/logs"
  "$COMFYUI_RUNTIME_DIR/workflows"
  "$COMFYUI_RUNTIME_DIR/ComfyUI/models/checkpoints"
  "$COMFYUI_RUNTIME_DIR/ComfyUI/models/clip"
  "$COMFYUI_RUNTIME_DIR/ComfyUI/models/text_encoders"
  "$COMFYUI_RUNTIME_DIR/ComfyUI/models/vae"
  "$COMFYUI_RUNTIME_DIR/ComfyUI/models/unet"
)

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui|/home/cuneyt/MoE/runtime/media-engines/comfyui/*)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must stay under /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

echo "Checking planned ComfyUI runtime layout"
echo "  runtime dir: $COMFYUI_RUNTIME_DIR"
echo "  create mode: $CREATE"

if [ "$CREATE" = "1" ]; then
  echo "Creating missing planned runtime directories under $COMFYUI_RUNTIME_DIR"
  for dir in "${planned_dirs[@]}"; do
    mkdir -p "$dir"
  done
fi

missing=0
for dir in "${planned_dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo "PASS: $dir"
  else
    echo "MISSING: $dir"
    missing=1
  fi
done

echo "INFO: This check does not install ComfyUI, create model symlinks, touch model files, or run GPU jobs."

if [ "$missing" = "1" ]; then
  echo "WARN: Some planned directories are missing. Run CREATE=1 scripts/check-comfyui-layout.sh only when manually preparing runtime layout."
else
  echo "PASS: planned ComfyUI runtime directories exist."
fi

exit 0
