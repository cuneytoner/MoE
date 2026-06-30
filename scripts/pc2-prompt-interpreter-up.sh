#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_SOURCE_ROOT="${PC2_SOURCE_ROOT:-/home/cuneyt/MoE/codebase}"
PC2_RUNTIME_ROOT="${PC2_RUNTIME_ROOT:-/home/cuneyt/MoE/runtime}"
PC2_COMPOSE_FILE="${PC2_COMPOSE_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/docker-compose.worker.example.yml}"
PC2_ENV_FILE="${PC2_ENV_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/.env.example}"

echo "Starting PC-2 Prompt Interpreter Worker only"
echo "  host: ${PC2_USER}@${PC2_HOST}"
echo "  compose: ${PC2_COMPOSE_FILE}"
echo "  service: prompt-interpreter-worker"

ssh -o BatchMode=yes "${PC2_USER}@${PC2_HOST}" \
  "mkdir -p '${PC2_RUNTIME_ROOT}/reports/prompt-interpreter' && \
   cd '${PC2_SOURCE_ROOT}' && \
   docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile prompt up -d --build prompt-interpreter-worker && \
   docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile prompt ps prompt-interpreter-worker"

echo "PASS: PC-2 Prompt Interpreter Worker start command completed"
