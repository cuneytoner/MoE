#!/usr/bin/env bash
set -euo pipefail

COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
COMFYUI_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI"
COMFYUI_VENV="$COMFYUI_RUNTIME_DIR/venv"

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must be /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

echo "Checking ComfyUI runtime"
echo "  runtime dir: $COMFYUI_RUNTIME_DIR"

warn=0

check_dir() {
  local path="$1"
  local label="$2"

  if [ -d "$path" ]; then
    echo "PASS: $label: $path"
  else
    echo "WARN: missing $label: $path"
    warn=1
  fi
}

check_file() {
  local path="$1"
  local label="$2"

  if [ -f "$path" ]; then
    echo "PASS: $label: $path"
  else
    echo "WARN: missing $label: $path"
    warn=1
  fi
}

check_exec() {
  local path="$1"
  local label="$2"

  if [ -x "$path" ]; then
    echo "PASS: $label: $path"
  else
    echo "WARN: missing executable $label: $path"
    warn=1
  fi
}

check_dir "$COMFYUI_RUNTIME_DIR" "runtime directory"
check_dir "$COMFYUI_DIR" "ComfyUI checkout"
check_dir "$COMFYUI_VENV" "runtime venv"
check_exec "$COMFYUI_VENV/bin/python" "venv python"
check_file "$COMFYUI_DIR/main.py" "ComfyUI main.py"
check_dir "$COMFYUI_DIR/models/checkpoints" "checkpoints model folder"
check_dir "$COMFYUI_DIR/models/clip" "clip model folder"
check_dir "$COMFYUI_DIR/models/text_encoders" "text_encoders model folder"
check_dir "$COMFYUI_DIR/models/vae" "vae model folder"
check_dir "$COMFYUI_DIR/models/unet" "unet model folder"

if [ "$warn" = "1" ]; then
  echo "WARN: ComfyUI runtime is not fully installed yet."
else
  echo "PASS: ComfyUI runtime layout looks ready."
fi

exit 0
