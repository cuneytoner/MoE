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
    -d '{"model":"local-gateway","messages":[{"role":"system","content":"You are a concise local coding assistant."},{"role":"user","content":"Return only the word OK."}],"temperature":0.2,"max_tokens":16,"stream":false}' \
    "$GATEWAY_API_URL/v1/chat/completions"
)"; then
  fail "Gateway OpenAI-compatible chat request failed"
fi

status_object="$(jq -r '.object // empty' <<<"$response")"
content="$(jq -r '.choices[0].message.content // empty' <<<"$response")"

if [ "$status_object" = "chat.completion" ] && [ -n "$content" ]; then
  pass "Gateway OpenAI-compatible chat for Continue.dev"
else
  fail "Gateway OpenAI-compatible chat returned unexpected response: $response"
fi
