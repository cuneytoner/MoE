#!/usr/bin/env bash
set -euo pipefail

MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"
REQUIRE_READY="${REQUIRE_READY:-0}"

FLUX_MODEL="$MODEL_BACKUP_DIR/flux/flux1-schnell.safetensors"
AE_MODEL="$MODEL_BACKUP_DIR/vae/ae.safetensors"

case "$MODEL_BACKUP_DIR" in
  /home/cuneyt/MoE_Models_Backup|/home/cuneyt/MoE_Models_Backup/*)
    ;;
  *)
    echo "FAIL: MODEL_BACKUP_DIR must stay under /home/cuneyt/MoE_Models_Backup"
    exit 1
    ;;
esac

find_first() {
  local pattern="$1"
  find "$MODEL_BACKUP_DIR" -maxdepth 5 -iname "$pattern" -type f -print 2>/dev/null | sort | head -n 1 || true
}

is_lfs_pointer() {
  local path="$1"
  head -c 128 "$path" 2>/dev/null | grep -q "version https://git-lfs.github.com/spec/v1"
}

check_file() {
  local label="$1"
  local path="$2"
  local min_bytes="$3"

  if [ ! -f "$path" ]; then
    echo "WARN: missing $label: $path"
    return 1
  fi
  if is_lfs_pointer "$path"; then
    echo "FAIL: $label appears to be a Git LFS pointer: $path"
    return 2
  fi
  size="$(stat -c '%s' "$path")"
  if [ "$size" -lt "$min_bytes" ]; then
    echo "WARN: $label size looks too small: $path size=$size"
    return 1
  fi
  echo "PASS: $label exists: $path size=$size"
  return 0
}

missing=0
failed=0

echo "Checking Flux Schnell model components"
echo "  model backup dir: $MODEL_BACKUP_DIR"

check_file "Flux Schnell main model" "$FLUX_MODEL" 1000000000 || rc="$?"
rc="${rc:-0}"
if [ "$rc" = "1" ]; then missing=1; elif [ "$rc" = "2" ]; then failed=1; fi
unset rc

check_file "Flux AE/VAE" "$AE_MODEL" 10000000 || rc="$?"
rc="${rc:-0}"
if [ "$rc" = "1" ]; then missing=1; elif [ "$rc" = "2" ]; then failed=1; fi
unset rc

clip_l="$(find_first "clip_l.safetensors")"
t5xxl="$(find_first "t5xxl_fp8_e4m3fn.safetensors")"

if [ -n "$clip_l" ]; then
  check_file "clip_l text encoder" "$clip_l" 1000000 || rc="$?"
  rc="${rc:-0}"
  if [ "$rc" = "1" ]; then missing=1; elif [ "$rc" = "2" ]; then failed=1; fi
  unset rc
else
  echo "WARN: missing clip_l.safetensors under $MODEL_BACKUP_DIR"
  missing=1
fi

if [ -n "$t5xxl" ]; then
  check_file "t5xxl text encoder" "$t5xxl" 1000000 || rc="$?"
  rc="${rc:-0}"
  if [ "$rc" = "1" ]; then missing=1; elif [ "$rc" = "2" ]; then failed=1; fi
  unset rc
else
  echo "WARN: missing t5xxl_fp8_e4m3fn.safetensors under $MODEL_BACKUP_DIR"
  missing=1
fi

if [ "$failed" = "1" ]; then
  echo "FAIL: one or more model files failed validation."
  exit 1
fi

if [ "$missing" = "1" ]; then
  if [ "$REQUIRE_READY" = "1" ]; then
    echo "FAIL: Flux Schnell model set is incomplete."
    exit 1
  fi
  echo "WARN: Flux Schnell model set is incomplete. Planning checks exit 0 by default."
  exit 0
fi

echo "PASS: Flux Schnell model set looks ready."
