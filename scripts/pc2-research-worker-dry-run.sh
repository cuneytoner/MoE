#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
RESEARCH_PORT="${RESEARCH_PORT:-8210}"
RUN_URL="http://${PC2_HOST}:${RESEARCH_PORT}/research/run"
PAYLOAD='{"mode":"dry_run","source_set":"default","store_findings":false}'

echo "Running PC-2 Research Ingestion Worker dry run"
echo "  url: ${RUN_URL}"
echo "  store_findings: false"

curl -fsS \
  -H "Content-Type: application/json" \
  -X POST \
  -d "${PAYLOAD}" \
  "${RUN_URL}"

echo ""
echo "PASS: PC-2 Research Ingestion Worker dry run request completed"
