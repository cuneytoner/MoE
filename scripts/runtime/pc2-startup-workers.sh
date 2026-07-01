#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="deploy/pc2/docker-compose.worker.example.yml"
ENV_FILE="deploy/pc2/.env.example"

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

locate_codebase() {
  if [ -d "/home/cuneyt/MoE/codebase" ]; then
    printf '%s\n' "/home/cuneyt/MoE/codebase"
    return 0
  fi
  if [ -d "/home/cuneyt/MoE" ]; then
    printf '%s\n' "/home/cuneyt/MoE"
    return 0
  fi
  return 1
}

section "PC-2 worker startup"
if ! codebase="$(locate_codebase)"; then
  echo "FAIL: no PC-2 codebase directory found under /home/cuneyt/MoE"
  exit 1
fi
echo "Using codebase: $codebase"
cd "$codebase"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "FAIL: PC-2 worker compose file not found: $codebase/$COMPOSE_FILE"
  exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: PC-2 env example file not found: $codebase/$ENV_FILE"
  exit 1
fi

run_cmd docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile learning up -d --build nightly-learning-worker || true
run_cmd docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile research up -d --build research-ingestion-worker || true
run_cmd docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile feedback up -d --build feedback-worker || true
run_cmd docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile prompt up -d --build prompt-interpreter-worker || true

section "Docker containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

section "Prompt Interpreter health"
curl -s http://127.0.0.1:8230/health || true
echo ""
