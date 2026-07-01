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

wait_for_gateway() {
  local attempts=20
  local http_status

  for attempt in $(seq 1 "$attempts"); do
    http_status="$(
      curl -sS -o /tmp/moe-gateway-memory-ready.json -w "%{http_code}" \
        "$GATEWAY_API_URL/v1/models" 2>/dev/null || true
    )"
    if [ "$http_status" != "000" ]; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  return 1
}

post_json() {
  local path="$1"
  local payload="$2"

  curl -sS -o /tmp/moe-gateway-memory-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$payload" \
    "$GATEWAY_API_URL$path" || true
}

require_command curl
require_command jq

if ! wait_for_gateway; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

gateway_status="$(
  post_json "/gateway/chat" \
    '{"messages":[{"role":"user","content":"Say hello shortly."}],"max_tokens":64,"memory":"off"}'
)"
gateway_response="$(cat /tmp/moe-gateway-memory-response.json 2>/dev/null || true)"

case "$gateway_status" in
  200)
    status="$(jq -r '.status // empty' <<<"$gateway_response")"
    memory_mode="$(jq -r '.memory.mode // empty' <<<"$gateway_response")"
    memory_status="$(jq -r '.memory.status // empty' <<<"$gateway_response")"
    memory_injected="$(jq -r 'if has("memory") and (.memory | has("injected")) then (.memory.injected | tostring) else "" end' <<<"$gateway_response")"
    if [ "$status" = "ok" ] \
      && [ "$memory_mode" = "off" ] \
      && [ "$memory_status" = "disabled" ] \
      && [ "$memory_injected" = "false" ]; then
      pass "Gateway /gateway/chat memory=off metadata"
    elif [ "$status" = "unavailable" ]; then
      detail="$(jq -r '.detail // empty' <<<"$gateway_response")"
      skip "llama-server unavailable through Gateway chat: $detail"
    else
      fail "Gateway /gateway/chat returned bad memory contract: $gateway_response"
    fi
    ;;
  503)
    detail="$(jq -r '.detail // empty' <<<"$gateway_response")"
    skip "llama-server unavailable through Gateway chat: $detail"
    ;;
  *)
    fail "Gateway /gateway/chat returned HTTP $gateway_status: $gateway_response"
    ;;
esac

openai_status="$(
  post_json "/v1/chat/completions" \
    '{"model":"gateway-auto","messages":[{"role":"user","content":"What do you remember about my local MoE model setup?"}],"max_tokens":128,"temperature":0.2,"memory":"auto","memory_limit":3}'
)"
openai_response="$(cat /tmp/moe-gateway-memory-response.json 2>/dev/null || true)"

case "$openai_status" in
  200)
    object="$(jq -r '.object // empty' <<<"$openai_response")"
    content="$(jq -r '.choices[0].message.content // empty' <<<"$openai_response")"
    memory_mode="$(jq -r '.x_gateway_memory.mode // empty' <<<"$openai_response")"
    memory_status="$(jq -r '.x_gateway_memory.status // empty' <<<"$openai_response")"
    memory_limit="$(jq -r '.x_gateway_memory.limit // empty' <<<"$openai_response")"
    if [ "$object" = "chat.completion" ] \
      && [ -n "$content" ] \
      && [ "$memory_mode" = "auto" ] \
      && [ -n "$memory_status" ] \
      && [ "$memory_limit" = "3" ]; then
      pass "Gateway /v1/chat/completions memory metadata"
    else
      fail "Gateway /v1/chat/completions returned bad memory contract: $openai_response"
    fi
    ;;
  503)
    detail="$(jq -r '.detail // empty' <<<"$openai_response")"
    skip "llama-server unavailable through Gateway OpenAI chat: $detail"
    ;;
  *)
    fail "Gateway /v1/chat/completions returned HTTP $openai_status: $openai_response"
    ;;
esac

echo "Gateway memory injection test passed"
