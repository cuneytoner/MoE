#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"

echo "Flux Schnell model acquisition plan"
echo "  model backup dir: $MODEL_BACKUP_DIR"
echo ""
echo "This script does not download, copy, move, symlink, or modify model files."
echo ""

find_matches() {
  local pattern="$1"

  if [ ! -d "$MODEL_BACKUP_DIR" ]; then
    return 0
  fi

  find "$MODEL_BACKUP_DIR" -maxdepth 5 -iname "$pattern" -print 2>/dev/null | sort || true
}

print_component() {
  local label="$1"
  local pattern="$2"
  local matches

  matches="$(find_matches "$pattern")"
  if [ -n "$matches" ]; then
    echo "FOUND: $label"
    printf '%s\n' "$matches" | sed 's/^/  /'
  else
    echo "MISSING: $label"
  fi
}

if [ ! -d "$MODEL_BACKUP_DIR" ]; then
  echo "WARN: model backup directory does not exist: $MODEL_BACKUP_DIR"
fi

echo "Detected components:"
print_component "clip_l.safetensors" "clip_l.safetensors"
print_component "t5xxl_fp8_e4m3fn.safetensors" "t5xxl_fp8_e4m3fn.safetensors"
print_component "Flux Schnell main model candidates" "*flux*schnell*"
print_component "AE/VAE candidates" "*ae*.safetensors"
print_component "VAE candidates" "*vae*"
echo ""

echo "Missing components to resolve before real generation:"
if [ -z "$(find_matches "*flux*schnell*")" ]; then
  echo "  - main Flux Schnell model"
fi
if [ -z "$(find_matches "*ae*.safetensors")" ] && [ -z "$(find_matches "*vae*")" ]; then
  echo "  - VAE/AE"
fi
echo ""

echo "Recommended future target paths:"
echo "  $MODEL_BACKUP_DIR/flux/flux1-schnell.safetensors"
echo "  $MODEL_BACKUP_DIR/clip/clip_l.safetensors"
echo "  $MODEL_BACKUP_DIR/clip/t5xxl_fp8_e4m3fn.safetensors"
echo "  $MODEL_BACKUP_DIR/vae/ae.safetensors"
echo ""

echo "Future download commands, comments only:"
echo "  # mkdir -p $MODEL_BACKUP_DIR/flux $MODEL_BACKUP_DIR/clip $MODEL_BACKUP_DIR/vae"
echo "  # download Flux Schnell main model to $MODEL_BACKUP_DIR/flux/flux1-schnell.safetensors"
echo "  # download AE/VAE to $MODEL_BACKUP_DIR/vae/ae.safetensors"
echo "  # verify checksums before linking into ComfyUI"

exit 0
