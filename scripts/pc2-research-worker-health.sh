#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
RESEARCH_PORT="${RESEARCH_PORT:-8210}"
HEALTH_URL="http://${PC2_HOST}:${RESEARCH_PORT}/health"

echo "Checking PC-2 Research Ingestion Worker health"
echo "  url: ${HEALTH_URL}"

if curl -fsS "${HEALTH_URL}"; then
  echo ""
  echo "PASS: PC-2 Research Ingestion Worker HTTP health is reachable"
  exit 0
fi

echo "FAIL: PC-2 Research Ingestion Worker HTTP health is not reachable" >&2
exit 1
