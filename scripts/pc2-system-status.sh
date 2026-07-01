#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PROMPT_INTERPRETER_PORT="${PROMPT_INTERPRETER_PORT:-8230}"
SYSTEM_STATUS_URL="http://${PC2_HOST}:${PROMPT_INTERPRETER_PORT}/system/status"

echo "Checking PC-2 system status"
echo "  url: ${SYSTEM_STATUS_URL}"

response="$(curl -fsS "${SYSTEM_STATUS_URL}")"
printf '%s\n' "$response" | jq '{
  status,
  service,
  read_only,
  host_role,
  memory,
  cpu,
  disk,
  uptime
}'
