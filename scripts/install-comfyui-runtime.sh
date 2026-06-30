#!/usr/bin/env bash
set -euo pipefail

COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
COMFYUI_REPO_URL="${COMFYUI_REPO_URL:-https://github.com/comfy-org/comfyui}"
COMFYUI_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI"
COMFYUI_VENV="$COMFYUI_RUNTIME_DIR/venv"
COMFYUI_LOG_DIR="$COMFYUI_RUNTIME_DIR/logs"
COMFYUI_WORKFLOW_DIR="$COMFYUI_RUNTIME_DIR/workflows"

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must be /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

echo "Installing ComfyUI runtime scaffold"
echo "  runtime dir: $COMFYUI_RUNTIME_DIR"
echo "  repo: $COMFYUI_REPO_URL"
echo ""
echo "This script writes only under $COMFYUI_RUNTIME_DIR."
echo "It does not download models, start ComfyUI, or write into the codebase."
echo ""

mkdir -p "$COMFYUI_RUNTIME_DIR" "$COMFYUI_LOG_DIR" "$COMFYUI_WORKFLOW_DIR"

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "nvidia-smi:"
  nvidia-smi || true
else
  echo "WARN: nvidia-smi not found."
fi

if [ -d "$COMFYUI_DIR/.git" ]; then
  echo "PASS: ComfyUI repository already exists: $COMFYUI_DIR"
elif [ -e "$COMFYUI_DIR" ]; then
  echo "FAIL: ComfyUI path exists but is not a git checkout: $COMFYUI_DIR"
  exit 1
else
  echo "Cloning ComfyUI into runtime path"
  git clone "$COMFYUI_REPO_URL" "$COMFYUI_DIR"
fi

if [ -x "$COMFYUI_VENV/bin/python" ]; then
  echo "PASS: runtime venv already exists: $COMFYUI_VENV"
else
  echo "Creating runtime venv: $COMFYUI_VENV"
  python3 -m venv "$COMFYUI_VENV"
fi

if [ -f "$COMFYUI_DIR/requirements.txt" ]; then
  echo "Installing ComfyUI Python dependencies into runtime venv"
  "$COMFYUI_VENV/bin/python" -m pip install --upgrade pip
  "$COMFYUI_VENV/bin/python" -m pip install -r "$COMFYUI_DIR/requirements.txt"
else
  echo "WARN: requirements.txt not found in $COMFYUI_DIR"
fi

mkdir -p \
  "$COMFYUI_DIR/models/checkpoints" \
  "$COMFYUI_DIR/models/clip" \
  "$COMFYUI_DIR/models/text_encoders" \
  "$COMFYUI_DIR/models/vae" \
  "$COMFYUI_DIR/models/unet"

echo "PASS: ComfyUI runtime scaffold is prepared."
echo "INFO: Run make check-comfyui-runtime to verify layout."
