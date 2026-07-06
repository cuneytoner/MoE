#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section() {
  echo ""
  echo "== $1 =="
}

if [ "${APPLY:-0}" != "1" ]; then
  section "Dry-run guided image cycle"
  "$SCRIPT_DIR/image-readiness.sh"
  "$SCRIPT_DIR/image-dry-run.sh"
  section "Real generation commands"
  echo "APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh"
  echo "Note: STOP_LLM=1 uses make model-stop, not pkill."
  echo "APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh"
  echo "APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh"
  exit 0
fi

if [ "${CONFIRM_IMAGE_FULL_CYCLE:-0}" != "1" ]; then
  echo "Full real image cycle is guarded. Run:"
  echo "  APPLY=1 CONFIRM_IMAGE_FULL_CYCLE=1 scripts/image/image-full-cycle.sh"
  exit 1
fi

section "Prepare image mode"
APPLY=1 STOP_LLM=1 "$SCRIPT_DIR/image-mode-prepare.sh"

section "Run real image generation"
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true "$SCRIPT_DIR/image-real-run.sh"

if [ "${AUTO_SAFE_SHUTDOWN:-0}" = "1" ]; then
  section "Auto safe shutdown"
  APPLY=1 START_LLM=1 "$SCRIPT_DIR/image-safe-shutdown.sh"
else
  section "Manual safe shutdown reminder"
  echo "Run when ready:"
  echo "  APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh"
fi
