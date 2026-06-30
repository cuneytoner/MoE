#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_SOURCE_ROOT="${PC2_SOURCE_ROOT:-/home/cuneyt/MoE/codebase}"
PC2_COMPOSE_FILE="${PC2_COMPOSE_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/docker-compose.worker.example.yml}"
PC2_ENV_FILE="${PC2_ENV_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/.env.example}"
NIGHTLY_PORT="${NIGHTLY_PORT:-8200}"
HEALTH_URL="http://${PC2_HOST}:${NIGHTLY_PORT}/health"

echo "Checking PC-2 Nightly Learning Worker health"
echo "  url: ${HEALTH_URL}"

if curl -fsS "${HEALTH_URL}"; then
  echo ""
  echo "PASS: PC-2 Nightly Learning Worker HTTP health is reachable"
  exit 0
fi

echo "WARN: HTTP health check failed; checking PC-2 Docker service status over SSH" >&2

if ssh -o BatchMode=yes "${PC2_USER}@${PC2_HOST}" \
  "cd '${PC2_SOURCE_ROOT}' && docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile learning ps nightly-learning-worker"; then
  echo "FAIL: HTTP health check failed, but Docker service status was printed above" >&2
else
  echo "FAIL: HTTP health check and SSH Docker status check both failed" >&2
fi

exit 1
