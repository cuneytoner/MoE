#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
FEEDBACK_PORT="${FEEDBACK_PORT:-8220}"
HEALTH_URL="http://${PC2_HOST}:${FEEDBACK_PORT}/health"

echo "Checking PC-2 Feedback Worker health"
echo "  url: ${HEALTH_URL}"

if curl -fsS "${HEALTH_URL}"; then
  echo ""
  echo "PASS: PC-2 Feedback Worker HTTP health is reachable"
  exit 0
fi

echo "FAIL: PC-2 Feedback Worker HTTP health is not reachable" >&2
exit 1
