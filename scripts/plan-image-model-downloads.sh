#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"

echo "Image model download plan placeholder"
echo "  model backup dir: $MODEL_BACKUP_DIR"
echo "  default recommendation: Track A, Flux Schnell via ComfyUI"
echo ""
echo "This script only inspects existing filenames and prints missing components."
echo "It does not download, copy, move, modify, or symlink model files."
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
  echo ""
fi

echo "Existing component probe:"
print_component "clip_l.safetensors" "clip_l.safetensors"
print_component "t5xxl_fp8_e4m3fn.safetensors" "t5xxl_fp8_e4m3fn.safetensors"
print_component "likely Flux files" "*flux*"
print_component "likely SDXL files" "*sdxl*"
print_component "likely VAE files" "*vae*"
echo ""

echo "Track A: Flux Schnell via ComfyUI"
echo "  Recommended default track for future real generation."
echo "  Required components:"
print_component "main_flux_model" "*flux*schnell*"
print_component "clip_l" "clip_l.safetensors"
print_component "t5xxl" "t5xxl_fp8_e4m3fn.safetensors"
print_component "vae" "*vae*"
echo ""

echo "Track B: SDXL via ComfyUI"
echo "  Fallback planning track."
echo "  Required components:"
print_component "sdxl_checkpoint" "*sdxl*"
print_component "vae_optional" "*vae*"
echo ""

echo "INFO: Download commands are intentionally absent in Milestone 26.1-pre."
echo "INFO: Store future media models only under $MODEL_BACKUP_DIR."

exit 0
