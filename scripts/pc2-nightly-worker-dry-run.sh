#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
NIGHTLY_PORT="${NIGHTLY_PORT:-8200}"
RUN_URL="http://${PC2_HOST}:${NIGHTLY_PORT}/nightly/run"
PAYLOAD='{"mode":"dry_run","include_git_status":true,"include_gateway_summary":true,"include_memory_summary":true,"store_lessons":false}'

./scripts/pc2-nightly-worker-health.sh

echo "Running PC-2 Nightly Learning Worker dry run"
echo "  url: ${RUN_URL}"
echo "  store_lessons: false"

curl -fsS \
  -H "Content-Type: application/json" \
  -X POST \
  -d "${PAYLOAD}" \
  "${RUN_URL}"

echo ""
echo "PASS: PC-2 Nightly Learning Worker dry run request completed"
