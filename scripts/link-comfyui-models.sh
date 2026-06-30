#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"
COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
COMFYUI_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI"
APPLY="${APPLY:-0}"
DRY_RUN="${DRY_RUN:-1}"

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must be /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

if [ "$APPLY" = "1" ]; then
  DRY_RUN=0
fi

echo "ComfyUI model link plan"
echo "  model backup dir: $MODEL_BACKUP_DIR"
echo "  ComfyUI dir: $COMFYUI_DIR"
echo "  dry run: $DRY_RUN"
echo ""
echo "This script creates symlinks only when APPLY=1. It never copies or deletes model files."
echo ""

find_first() {
  local pattern="$1"

  if [ ! -d "$MODEL_BACKUP_DIR" ]; then
    return 0
  fi

  find "$MODEL_BACKUP_DIR" -maxdepth 5 -iname "$pattern" -type f -print 2>/dev/null | sort | head -n 1 || true
}

first_existing() {
  for path in "$@"; do
    if [ -f "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 0
}

link_model() {
  local label="$1"
  local source="$2"
  local target_dir="$3"
  local target_name="$4"
  local target="$target_dir/$target_name"

  if [ -z "$source" ]; then
    echo "MISSING: $label"
    return 0
  fi

  if [ ! -f "$source" ]; then
    echo "MISSING: $label source is not a file: $source"
    return 0
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "SKIP: $label target already exists: $target"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "WOULD LINK: $label"
    echo "  source: $source"
    echo "  target: $target"
    return 0
  fi

  mkdir -p "$target_dir"
  ln -s "$source" "$target"
  echo "LINKED: $label"
  echo "  source: $source"
  echo "  target: $target"
}

clip_l="$(first_existing "$MODEL_BACKUP_DIR/clip/clip_l.safetensors" "$MODEL_BACKUP_DIR/clip_l.safetensors")"
if [ -z "$clip_l" ]; then
  clip_l="$(find_first "clip_l.safetensors")"
fi
t5xxl="$(first_existing "$MODEL_BACKUP_DIR/clip/t5xxl_fp8_e4m3fn.safetensors" "$MODEL_BACKUP_DIR/t5xxl_fp8_e4m3fn.safetensors")"
if [ -z "$t5xxl" ]; then
  t5xxl="$(find_first "t5xxl_fp8_e4m3fn.safetensors")"
fi
flux_main="$(first_existing "$MODEL_BACKUP_DIR/flux/flux1-schnell.safetensors")"
if [ -z "$flux_main" ]; then
  flux_main="$(find_first "*flux*schnell*")"
fi
vae_or_ae="$(first_existing "$MODEL_BACKUP_DIR/vae/ae.safetensors")"
if [ -z "$vae_or_ae" ]; then
  vae_or_ae="$(find_first "*ae*.safetensors")"
fi
if [ -z "$vae_or_ae" ]; then
  vae_or_ae="$(find_first "*vae*")"
fi

link_model "clip_l.safetensors" "$clip_l" "$COMFYUI_DIR/models/clip" "clip_l.safetensors"
link_model "t5xxl_fp8_e4m3fn.safetensors" "$t5xxl" "$COMFYUI_DIR/models/text_encoders" "t5xxl_fp8_e4m3fn.safetensors"
link_model "Flux Schnell main model" "$flux_main" "$COMFYUI_DIR/models/unet" "flux1-schnell.safetensors"
link_model "VAE/AE" "$vae_or_ae" "$COMFYUI_DIR/models/vae" "ae.safetensors"

echo ""
if [ "$DRY_RUN" = "1" ]; then
  echo "INFO: Dry run complete. Use APPLY=1 scripts/link-comfyui-models.sh to create symlinks."
else
  echo "PASS: Symlink apply run complete."
fi
