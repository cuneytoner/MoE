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

post_json() {
  local path="$1"
  local body="$2"

  curl -sS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$body" \
    "$GATEWAY_API_URL$path"
}

wait_for_gateway() {
  local attempts=20

  for attempt in $(seq 1 "$attempts"); do
    if health_response="$(curl -fsS "$GATEWAY_API_URL/gateway/health" 2>/dev/null)" && \
      [ -n "$health_response" ]; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  return 1
}

require_command curl
require_command jq

if ! wait_for_gateway; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

payload='{"messages":[{"role":"user","content":"Say hello in one short sentence."}],"max_tokens":64,"temperature":0.2}'
if ! response="$(post_json "/gateway/chat" "$payload")"; then
  fail "Gateway chat proxy request failed"
fi

status="$(jq -r '.status // empty' <<<"$response")"
service="$(jq -r '.service // empty' <<<"$response")"
content="$(jq -r '.response // empty' <<<"$response")"
detail="$(jq -r '.detail // empty' <<<"$response")"

case "$status" in
  ok)
    if [ "$service" = "gateway-chat-proxy" ] && [ -n "$content" ]; then
      pass "Gateway chat proxy returned response"
    else
      fail "Gateway chat proxy returned bad ok contract: $response"
    fi
    ;;
  unavailable)
    if [ "$service" = "gateway-chat-proxy" ] && [ -n "$detail" ]; then
      skip "llama-server unavailable through Gateway: $detail"
    fi
    fail "Gateway chat proxy unavailable response missing detail: $response"
    ;;
  *)
    fail "Gateway chat proxy returned unexpected response: $response"
    ;;
esac

stream_http_status="$(
  curl -sS -o /tmp/moe-gateway-chat-proxy-stream-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"messages":[{"role":"user","content":"hello"}],"stream":true}' \
    "$GATEWAY_API_URL/gateway/chat" || true
)"

if [ "$stream_http_status" = "400" ]; then
  pass "Gateway chat proxy rejects streaming"
else
  stream_response="$(cat /tmp/moe-gateway-chat-proxy-stream-response.json 2>/dev/null || true)"
  fail "Gateway chat proxy expected HTTP 400 for stream=true, got $stream_http_status: $stream_response"
fi

echo "Gateway chat proxy test passed"
