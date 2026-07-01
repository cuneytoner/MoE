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
  section "Image safe shutdown plan"
  echo "This script returns media services to a safe dry state only with APPLY=1."
  echo "Planned fixed commands:"
  echo "  MEDIA_REAL_GENERATION_ENABLED=false docker compose -f $COMPOSE_FILE --profile media up -d --build media-api media-worker"
  echo "  make comfyui-down || true"
  echo "  If START_LLM=1: make model-switch MODEL=qwen-coder-14b-fast && make model-health"
  echo "  make media-dashboard-status || true"
  echo ""
  echo "Run:"
  echo "  APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh"
  exit 0
fi

section "Disable media real generation"
MEDIA_REAL_GENERATION_ENABLED=false docker compose -f "$COMPOSE_FILE" --profile media up -d --build media-api media-worker

section "Stop ComfyUI"
make comfyui-down || true

if [ "${START_LLM:-0}" = "1" ]; then
  section "Restart coding model"
  make model-switch MODEL=qwen-coder-14b-fast
  make model-health
else
  echo "START_LLM=1 was not set; coding model was not restarted."
fi

section "Media dashboard"
make media-dashboard-status || true

section "Done"
echo "Safe shutdown complete. Generated outputs were not deleted."
