#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
COMPOSE_FILE="infra/docker/docker-compose.yml"

section() {
  echo ""
  echo "== $1 =="
}

cd "$CODEBASE_DIR"

if [ "${APPLY:-0}" != "1" ]; then
  section "Image mode prepare plan"
  echo "This script prepares real image mode only with APPLY=1."
  echo "Planned fixed commands:"
  echo "  If STOP_LLM=1: make model-stop && make model-status"
  echo "  If STOP_LLM=1: pgrep -af 'llama-server.*--port 8000' || true"
  echo "  COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up"
  echo "  MEDIA_REAL_GENERATION_ENABLED=true docker compose -f $COMPOSE_FILE --profile media up -d --build media-api media-worker"
  echo "  scripts/image/image-readiness.sh"
  echo ""
  echo "Run:"
  echo "  APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh"
  exit 0
fi

section "Optional llama-server stop"
if [ "${STOP_LLM:-0}" = "1" ]; then
  make model-stop
  make model-status
  pgrep -af 'llama-server.*--port 8000' || true
else
  echo "STOP_LLM=1 was not set; llama-server was not stopped."
fi

section "Start ComfyUI bridge mode"
COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up

section "Start media services with real generation enabled"
MEDIA_REAL_GENERATION_ENABLED=true docker compose -f "$COMPOSE_FILE" --profile media up -d --build media-api media-worker

section "Readiness"
scripts/image/image-readiness.sh

section "Done"
echo "Image mode prepared. Gateway real generation remains separately guarded."
