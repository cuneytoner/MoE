#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
FEEDBACK_PORT="${FEEDBACK_PORT:-8220}"
RUN_URL="http://${PC2_HOST}:${FEEDBACK_PORT}/improvement/report"
OPENAPI_URL="http://${PC2_HOST}:${FEEDBACK_PORT}/openapi.json"
PAYLOAD='{"mode":"dry_run","limit":100,"include_router_recommendations":true,"include_model_mapping_recommendations":true,"include_prompt_recommendations":true,"include_test_recommendations":true,"store_lessons":false}'

./scripts/pc2-feedback-worker-health.sh

echo "Generating PC-2 prompt/routing improvement report"
echo "  url: ${RUN_URL}"
echo "  store_lessons: false"

response_file="$(mktemp)"
status="$(curl -sS \
  -o "$response_file" \
  -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "${PAYLOAD}" \
  "${RUN_URL}")"

if [ "$status" = "404" ]; then
  echo "FAIL: /improvement/report returned HTTP 404; printing OpenAPI paths for stale route/image diagnosis" >&2
  curl -fsS "${OPENAPI_URL}" | jq -r '.paths | keys[]' >&2 || curl -fsS "${OPENAPI_URL}" >&2 || true
  rm -f "$response_file"
  exit 1
fi

if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
  echo "FAIL: /improvement/report returned HTTP ${status}" >&2
  cat "$response_file" >&2
  rm -f "$response_file"
  exit 1
fi

cat "$response_file"
rm -f "$response_file"

echo ""
echo "PASS: PC-2 improvement report dry run request completed"
