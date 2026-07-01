#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
COMPOSE_FILE="infra/docker/docker-compose.yml"

section() {
  echo ""
  echo "== $1 =="
}

run_cmd() {
  echo "+ $*"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  "$@"
}

section "PC-1 sleep prepare"
cd "$CODEBASE_DIR"

section "Disable media real generation"
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "+ MEDIA_REAL_GENERATION_ENABLED=false docker compose -f $COMPOSE_FILE --profile media up -d --build media-api media-worker"
else
  MEDIA_REAL_GENERATION_ENABLED=false docker compose -f "$COMPOSE_FILE" --profile media up -d --build media-api media-worker
fi

section "Stop ComfyUI"
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "+ make comfyui-down || true"
else
  make comfyui-down || true
fi

section "llama-server status"
pgrep -af 'llama-server.*--port 8000' || true
if [ "${STOP_LLM:-0}" = "1" ]; then
  run_cmd pkill -f 'llama-server.*--port 8000' || true
else
  echo "STOP_LLM=1 was not set; llama-server was not stopped."
fi

section "Docker containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

section "GPU status"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi not available"
fi

section "Done"
echo "PC-1 sleep prepare complete. This script does not suspend."
