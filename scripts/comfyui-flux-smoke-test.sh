#!/usr/bin/env bash
set -euo pipefail

COMFYUI_URL="${COMFYUI_URL:-http://127.0.0.1:8188}"
COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
OUTPUT_DIR="${MEDIA_IMAGE_OUTPUT_DIR:-/home/cuneyt/MoE/runtime/media/outputs/images}"

COMFYUI_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI"

echo "ComfyUI Flux smoke readiness"
echo "  ComfyUI url: $COMFYUI_URL"
echo "  ComfyUI dir: $COMFYUI_DIR"
echo "  output dir: $OUTPUT_DIR"

ready=1

if curl -fsS "$COMFYUI_URL/" >/dev/null 2>&1; then
  echo "PASS: ComfyUI health reachable"
else
  echo "WARN: ComfyUI is not reachable at $COMFYUI_URL"
  ready=0
fi

check_link() {
  local label="$1"
  local path="$2"

  if [ -e "$path" ]; then
    echo "PASS: $label linked/present: $path"
  else
    echo "WARN: missing $label link: $path"
    ready=0
  fi
}

check_link "Flux model" "$COMFYUI_DIR/models/unet/flux1-schnell.safetensors"
check_link "AE/VAE" "$COMFYUI_DIR/models/vae/ae.safetensors"
check_link "clip_l" "$COMFYUI_DIR/models/clip/clip_l.safetensors"
check_link "t5xxl" "$COMFYUI_DIR/models/text_encoders/t5xxl_fp8_e4m3fn.safetensors"

if [ -d "$OUTPUT_DIR" ]; then
  echo "PASS: output dir exists: $OUTPUT_DIR"
else
  echo "WARN: output dir missing: $OUTPUT_DIR"
  ready=0
fi

"$(dirname "${BASH_SOURCE[0]}")/comfyui-vram-status.sh" || true

if [ "$ready" = "1" ]; then
  echo "PASS: ComfyUI Flux smoke readiness looks OK."
else
  echo "WARN: ComfyUI Flux smoke readiness is incomplete."
fi

echo "INFO: This smoke test does not submit a workflow."
exit 0
