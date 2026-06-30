#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_SOURCE_ROOT="${PC2_SOURCE_ROOT:-/home/cuneyt/MoE/codebase}"
PC2_COMPOSE_FILE="${PC2_COMPOSE_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/docker-compose.worker.example.yml}"
PC2_ENV_FILE="${PC2_ENV_FILE:-${PC2_SOURCE_ROOT}/deploy/pc2/.env.example}"

echo "Stopping PC-2 Nightly Learning Worker only"
echo "  host: ${PC2_USER}@${PC2_HOST}"
echo "  service: nightly-learning-worker"
echo "  remove volumes: no"
echo "  delete reports: no"

ssh -o BatchMode=yes "${PC2_USER}@${PC2_HOST}" \
  "cd '${PC2_SOURCE_ROOT}' && \
   docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile learning stop nightly-learning-worker && \
   docker compose --env-file '${PC2_ENV_FILE}' -f '${PC2_COMPOSE_FILE}' --profile learning ps nightly-learning-worker"

echo "PASS: PC-2 Nightly Learning Worker stop command completed"
