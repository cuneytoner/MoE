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

section "PC-1 coding startup"
cd "$CODEBASE_DIR"

section "Source status"
git status --short

section "Start safe base Docker stack"
run_cmd docker compose -f "$COMPOSE_FILE" --profile media up -d --build gateway-api memory-api embed-worker media-api media-worker postgres qdrant

section "Keep media real generation disabled"
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "+ MEDIA_REAL_GENERATION_ENABLED=false docker compose -f $COMPOSE_FILE --profile media up -d --build media-api media-worker"
else
  MEDIA_REAL_GENERATION_ENABLED=false docker compose -f "$COMPOSE_FILE" --profile media up -d --build media-api media-worker
fi

section "Start coding model"
run_cmd make model-switch MODEL=qwen-coder-14b-fast

section "Health checks"
run_cmd make model-health
run_cmd make media-dashboard-status

section "Useful URLs"
echo "Gateway: http://127.0.0.1:8100/gateway/health"
echo "Gateway media dashboard: http://127.0.0.1:8100/gateway/media/dashboard"
echo "OpenAI-compatible Gateway: http://127.0.0.1:8100/v1"
