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

section "PC-1 media dry-run startup"
cd "$CODEBASE_DIR"

section "Start safe base Docker stack"
run_cmd docker compose -f "$COMPOSE_FILE" --profile media up -d --build gateway-api memory-api embed-worker media-api media-worker postgres qdrant

section "Keep media real generation disabled"
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "+ MEDIA_REAL_GENERATION_ENABLED=false docker compose -f $COMPOSE_FILE --profile media up -d --build media-api media-worker"
else
  MEDIA_REAL_GENERATION_ENABLED=false docker compose -f "$COMPOSE_FILE" --profile media up -d --build media-api media-worker
fi

section "Dry-run media checks"
run_cmd make gateway-media-plan
run_cmd make gateway-media-dry-run
run_cmd make media-dashboard-status

section "Done"
echo "ComfyUI external bridge was not started. Real generation remains disabled."
