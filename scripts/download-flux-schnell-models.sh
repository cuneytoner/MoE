#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"
APPLY="${APPLY:-0}"
FORCE="${FORCE:-0}"
FLUX_DIR="$MODEL_BACKUP_DIR/flux"
VAE_DIR="$MODEL_BACKUP_DIR/vae"
CLIP_DIR="$MODEL_BACKUP_DIR/clip"
FLUX_TARGET="$FLUX_DIR/flux1-schnell.safetensors"
AE_TARGET="$VAE_DIR/ae.safetensors"
CLIP_L_TARGET="$CLIP_DIR/clip_l.safetensors"
T5XXL_TARGET="$CLIP_DIR/t5xxl_fp8_e4m3fn.safetensors"

case "$MODEL_BACKUP_DIR" in
  /home/cuneyt/MoE_Models_Backup|/home/cuneyt/MoE_Models_Backup/*)
    ;;
  *)
    echo "FAIL: MODEL_BACKUP_DIR must stay under /home/cuneyt/MoE_Models_Backup"
    exit 1
    ;;
esac

echo "Flux Schnell model download plan"
echo "  model backup dir: $MODEL_BACKUP_DIR"
echo "  apply: $APPLY"
echo "  force: $FORCE"
echo ""
echo "Target paths:"
echo "  $FLUX_TARGET"
echo "  $AE_TARGET"
echo "  $CLIP_L_TARGET"
echo "  $T5XXL_TARGET"
echo ""

if [ "$APPLY" != "1" ]; then
  echo "DRY RUN: no files will be downloaded."
  echo ""
  echo "Future commands this script will run with APPLY=1:"
  echo "  hf download black-forest-labs/FLUX.1-schnell flux1-schnell.safetensors --local-dir $FLUX_DIR"
  echo "  hf download black-forest-labs/FLUX.1-schnell ae.safetensors --local-dir $VAE_DIR"
  echo "  hf download comfyanonymous/flux_text_encoders clip_l.safetensors --local-dir $CLIP_DIR"
  echo "  hf download comfyanonymous/flux_text_encoders t5xxl_fp8_e4m3fn.safetensors --local-dir $CLIP_DIR"
  echo ""
  echo "Gated model note:"
  echo "  If black-forest-labs/FLUX.1-schnell requires approval, open:"
  echo "  https://huggingface.co/black-forest-labs/FLUX.1-schnell"
  echo "  accept/request access, then run 'hf auth login' and retry."
  echo ""
  echo "INFO: If text encoders already exist at $MODEL_BACKUP_DIR, keep them there or move/copy manually after reviewing disk layout."
  exit 0
fi

echo "APPLY=1 set. Downloads will be written only under $MODEL_BACKUP_DIR."

if ! command -v hf >/dev/null 2>&1; then
  echo "FAIL: hf is not installed."
  echo ""
  echo "Install it in a repo-external environment, for example:"
  echo "  mkdir -p ~/MoE/runtime/venvs"
  echo "  python3 -m venv ~/MoE/runtime/venvs/huggingface"
  echo "  source ~/MoE/runtime/venvs/huggingface/bin/activate"
  echo "  pip install -U huggingface_hub"
  echo "  make download-flux-schnell-models-apply"
  exit 1
fi

mkdir -p "$FLUX_DIR" "$VAE_DIR" "$CLIP_DIR"

download_file() {
  local label="$1"
  local target="$2"
  local repo="$3"
  local include="$4"
  local dir="$5"

  if [ -f "$target" ] && [ "$FORCE" != "1" ]; then
    echo "SKIP: $label already exists: $target"
    return 0
  fi

  if [ -f "$target" ] && [ "$FORCE" = "1" ]; then
    echo "WARN: FORCE=1 set; hf may overwrite existing $label."
  fi

  echo "Downloading $label"
  if ! output="$(hf download "$repo" "$include" --local-dir "$dir" 2>&1)"; then
    printf '%s\n' "$output"
    case "$output" in
      *"Access denied"*|*"access denied"*|*"requires approval"*|*"approval"*|*"gated"*|*"Gated"*)
        echo ""
        echo "Flux Schnell appears to be gated or access-restricted."
        echo "Open https://huggingface.co/black-forest-labs/FLUX.1-schnell"
        echo "accept/request access"
        echo "then run hf auth login and retry."
        ;;
    esac
    return 1
  fi
  printf '%s\n' "$output"
}

download_file "Flux Schnell main model" "$FLUX_TARGET" "black-forest-labs/FLUX.1-schnell" "flux1-schnell.safetensors" "$FLUX_DIR"
download_file "Flux AE/VAE" "$AE_TARGET" "black-forest-labs/FLUX.1-schnell" "ae.safetensors" "$VAE_DIR"
download_file "clip_l text encoder" "$CLIP_L_TARGET" "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$CLIP_DIR"
download_file "t5xxl text encoder" "$T5XXL_TARGET" "comfyanonymous/flux_text_encoders" "t5xxl_fp8_e4m3fn.safetensors" "$CLIP_DIR"

echo "PASS: Flux Schnell download command completed."
