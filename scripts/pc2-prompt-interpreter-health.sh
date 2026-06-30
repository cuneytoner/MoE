#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PROMPT_INTERPRETER_PORT="${PROMPT_INTERPRETER_PORT:-8230}"
HEALTH_URL="http://${PC2_HOST}:${PROMPT_INTERPRETER_PORT}/health"
MAX_ATTEMPTS="${PC2_HTTP_MAX_ATTEMPTS:-20}"
SLEEP_SECONDS="${PC2_HTTP_SLEEP_SECONDS:-1}"

echo "Checking PC-2 Prompt Interpreter Worker health"
echo "  url: ${HEALTH_URL}"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "Attempt ${attempt}/${MAX_ATTEMPTS}: GET ${HEALTH_URL}"
  if response="$(curl -fsS "${HEALTH_URL}" 2>/dev/null)" && printf '%s' "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"'; then
    printf '%s\n' "$response"
    echo "PASS: PC-2 Prompt Interpreter Worker HTTP health is reachable"
    exit 0
  fi
  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    sleep "$SLEEP_SECONDS"
  fi
done

echo "FAIL: PC-2 Prompt Interpreter Worker HTTP health is not reachable" >&2
exit 1
