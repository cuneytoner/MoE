#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

pass() {
  echo "PASS: $1"
}

skip() {
  echo "SKIP: $1"
  exit 0
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

if ! curl -fsS "$GATEWAY_API_URL/v1/models" >/dev/null 2>&1; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

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

if ! continue_response="$(
  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"local-gateway","messages":[{"role":"system","content":"You are a concise local coding assistant."},{"role":"user","content":"Return only the word OK."}],"temperature":0.2,"max_tokens":16,"stream":true,"tools":[{"type":"function","function":{"name":"shell","description":"must not run","parameters":{"type":"object","properties":{}}}}],"tool_choice":"auto","parallel_tool_calls":true,"response_format":{"type":"text"},"stop":["\n\n"],"presence_penalty":0,"frequency_penalty":0,"top_p":1,"n":1,"user":"continue"}' \
    "$GATEWAY_API_URL/v1/chat/completions"
)"; then
  fail "Gateway Continue-compatible stream/tool payload request failed"
fi

continue_content="$(jq -r '.choices[0].message.content // empty' <<<"$continue_response")"
stream_requested="$(jq -r '.x_gateway_compat.stream_requested' <<<"$continue_response")"
stream_normalized="$(jq -r '.x_gateway_compat.stream_normalized' <<<"$continue_response")"
tools_ignored="$(jq -r '.x_gateway_compat.tools_ignored' <<<"$continue_response")"
tool_choice_ignored="$(jq -r '.x_gateway_compat.tool_choice_ignored' <<<"$continue_response")"

if [ -n "$continue_content" ] \
  && [ "$stream_requested" = "true" ] \
  && [ "$stream_normalized" = "true" ] \
  && [ "$tools_ignored" = "true" ] \
  && [ "$tool_choice_ignored" = "true" ]; then
  pass "Gateway normalizes Continue.dev stream/tool payloads without tool execution"
else
  fail "Gateway Continue-compatible payload returned unexpected response: $continue_response"
fi
