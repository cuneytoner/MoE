#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_SOURCE_ROOT="${PC2_SOURCE_ROOT:-/home/cuneyt/MoE/codebase}"
PC2_COMPOSE_FILE="${PC2_COMPOSE_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/docker-compose.worker.example.yml}"
PC2_ENV_FILE="${PC2_ENV_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/.env.example}"
NIGHTLY_PORT="${NIGHTLY_PORT:-8200}"
HEALTH_URL="http://${PC2_HOST}:${NIGHTLY_PORT}/health"
MAX_ATTEMPTS="${PC2_HTTP_MAX_ATTEMPTS:-20}"
SLEEP_SECONDS="${PC2_HTTP_SLEEP_SECONDS:-1}"

echo "Checking PC-2 Nightly Learning Worker health"
echo "  url: ${HEALTH_URL}"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "Attempt ${attempt}/${MAX_ATTEMPTS}: GET ${HEALTH_URL}"
  if response="$(curl -fsS "${HEALTH_URL}" 2>/dev/null)" && printf '%s' "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"'; then
    printf '%s\n' "$response"
    echo "PASS: PC-2 Nightly Learning Worker HTTP health is reachable"
    exit 0
  fi
  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    sleep "$SLEEP_SECONDS"
  fi
done

echo "FAIL: PC-2 Nightly Learning Worker HTTP health is not reachable" >&2
echo "PC-2 Docker status:" >&2
ssh -o BatchMode=yes "${PC2_USER}@${PC2_HOST}" \
  "cd '${PC2_SOURCE_ROOT}' && docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile learning ps nightly-learning-worker" >&2 || true
echo "PC-2 recent nightly-learning-worker logs:" >&2
ssh -o BatchMode=yes "${PC2_USER}@${PC2_HOST}" \
  "cd '${PC2_SOURCE_ROOT}' && docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile learning logs --tail=80 nightly-learning-worker" >&2 || true

exit 1
