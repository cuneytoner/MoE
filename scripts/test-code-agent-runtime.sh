#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://localhost:8100}"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "$1 is required"
  fi
}

require_command curl
require_command jq

if ! response="$(
  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"task":"Return a one sentence summary of docs/gateway-api.md","query":"Gateway API","paths":["docs/gateway-api.md"],"max_files":4,"max_context_chars":12000,"temperature":0.1,"max_tokens":128,"use_memory":false,"auto_route":true}' \
    "$GATEWAY_API_URL/gateway/code/ask"
)"; then
  fail "Gateway code agent runtime request failed"
fi

status="$(jq -r '.status // empty' <<<"$response")"
content="$(jq -r '.content // empty' <<<"$response")"

if [ "$status" = "ok" ] && [ -n "$content" ]; then
  pass "Gateway repo-aware code agent runtime"
else
  fail "Gateway code agent runtime returned unexpected response: $response"
fi
