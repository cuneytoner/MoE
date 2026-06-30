#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
FEEDBACK_PORT="${FEEDBACK_PORT:-8220}"
BASE_URL="http://${PC2_HOST}:${FEEDBACK_PORT}"
EVENT_PAYLOAD='{"task_type":"coding","goal":"sample PC-2 feedback event","route_intent":"code","model_target":"qwen-coder-14b-fast","actual_model":"qwen-coder-14b-fast","tools":["code_context"],"selected_files":["docs/feedback-success-memory.md"],"tests_run":["make test"],"outcome":"success","failure_reason":"","notes":"sample event from pc2-feedback-worker-sample.sh"}'
REPORT_PAYLOAD='{"mode":"dry_run","limit":100,"store_lessons":false}'

./scripts/pc2-feedback-worker-health.sh

echo "Posting sample PC-2 Feedback Worker event"
echo "  url: ${BASE_URL}/feedback/event"
curl -fsS \
  -H "Content-Type: application/json" \
  -X POST \
  -d "${EVENT_PAYLOAD}" \
  "${BASE_URL}/feedback/event"

echo ""
echo "Generating PC-2 Feedback Worker dry-run report"
echo "  url: ${BASE_URL}/feedback/report"
echo "  store_lessons: false"
curl -fsS \
  -H "Content-Type: application/json" \
  -X POST \
  -d "${REPORT_PAYLOAD}" \
  "${BASE_URL}/feedback/report"

echo ""
echo "PASS: PC-2 Feedback Worker sample event and dry-run report completed"
echo "Hint: run 'make pc2-improvement-report' to generate advisory prompt/routing recommendations."
