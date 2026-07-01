#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="deploy/pc2/docker-compose.worker.example.yml"
ENV_FILE="deploy/pc2/.env.example"

section() {
  echo ""
  echo "== $1 =="
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

section "PC-2 sleep prepare"
if codebase="$(locate_codebase)"; then
  echo "Using codebase: $codebase"
  cd "$codebase"
  if [ -f "$COMPOSE_FILE" ]; then
    echo "+ docker compose --env-file $ENV_FILE -f $COMPOSE_FILE down || true"
    if [ "${DRY_RUN:-0}" != "1" ]; then
      docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down || true
    fi
  else
    echo "WARN: PC-2 worker compose file not found: $codebase/$COMPOSE_FILE"
  fi
else
  echo "WARN: no PC-2 codebase directory found under /home/cuneyt/MoE"
fi

section "Docker containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

section "Done"
echo "PC-2 sleep prepare complete. This script does not suspend."
