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
      curl -sS -o /tmp/moe-openai-gateway-ready.json -w "%{http_code}" \
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

require_command curl
require_command jq

if ! wait_for_gateway; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

models_http_status="$(
  curl -sS -o /tmp/moe-openai-gateway-models.json -w "%{http_code}" \
    "$GATEWAY_API_URL/v1/models" || true
)"
models_response="$(cat /tmp/moe-openai-gateway-models.json 2>/dev/null || true)"

case "$models_http_status" in
  200)
    models_type="$(jq -r 'if (.data | type) == "array" then "array" else "other" end' <<<"$models_response")"
    if [ "$models_type" = "array" ]; then
      pass "Gateway OpenAI /v1/models"
    else
      fail "Gateway OpenAI /v1/models returned bad contract: $models_response"
    fi
    ;;
  503)
    detail="$(jq -r '.detail // empty' <<<"$models_response")"
    if [ -n "$detail" ]; then
      skip "llama-server unavailable through Gateway /v1/models: $detail"
    fi
    fail "Gateway OpenAI /v1/models 503 missing detail: $models_response"
    ;;
  *)
    fail "Gateway OpenAI /v1/models returned HTTP $models_http_status: $models_response"
    ;;
esac

chat_http_status="$(
  curl -sS -o /tmp/moe-openai-gateway-chat.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Say hello in one short sentence."}],"max_tokens":64,"temperature":0.2,"routing":"auto"}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
chat_response="$(cat /tmp/moe-openai-gateway-chat.json 2>/dev/null || true)"

case "$chat_http_status" in
  200)
    object="$(jq -r '.object // empty' <<<"$chat_response")"
    content="$(jq -r '.choices[0].message.content // empty' <<<"$chat_response")"
    router_mode="$(jq -r '.x_gateway_router.mode // .router.mode // empty' <<<"$chat_response")"
    router_intent="$(jq -r '.x_gateway_router.intent // .router.intent // empty' <<<"$chat_response")"
    if [ "$object" = "chat.completion" ] \
      && [ -n "$content" ] \
      && [ "$router_mode" = "advisory" ] \
      && [ -n "$router_intent" ]; then
      pass "Gateway OpenAI /v1/chat/completions"
    else
      fail "Gateway OpenAI /v1/chat/completions returned bad contract: $chat_response"
    fi
    ;;
  503)
    error_message="$(jq -r '.error.message // empty' <<<"$chat_response")"
    error_code="$(jq -r '.error.code // empty' <<<"$chat_response")"
    if [ -n "$error_message" ] && [ -n "$error_code" ]; then
      skip "llama-server unavailable through Gateway chat: $error_message"
    fi
    fail "Gateway OpenAI /v1/chat/completions 503 missing JSON error body: $chat_response"
    ;;
  *)
    fail "Gateway OpenAI /v1/chat/completions returned HTTP $chat_http_status: $chat_response"
    ;;
esac

stream_http_status="$(
  curl -sS -D /tmp/moe-openai-gateway-stream-headers.txt \
    -o /tmp/moe-openai-gateway-stream.txt \
    -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"gateway-auto","messages":[{"role":"user","content":"hello"}],"stream":true}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
stream_headers="$(cat /tmp/moe-openai-gateway-stream-headers.txt 2>/dev/null || true)"
stream_response="$(cat /tmp/moe-openai-gateway-stream.txt 2>/dev/null || true)"

if [ "$stream_http_status" = "200" ] \
  && grep -qi 'content-type:.*text/event-stream' <<<"$stream_headers" \
  && grep -q 'data: ' <<<"$stream_response" \
  && grep -q '"object":"chat.completion.chunk"' <<<"$stream_response" \
  && grep -q '"choices"' <<<"$stream_response" \
  && grep -q '"stream_requested":true' <<<"$stream_response" \
  && grep -q '"stream_wrapped":true' <<<"$stream_response" \
  && grep -q '\[DONE\]' <<<"$stream_response"; then
  pass "Gateway OpenAI /v1/chat/completions wraps streaming as SSE"
else
  fail "Gateway OpenAI expected HTTP 200 SSE for stream=true, got $stream_http_status headers=[$stream_headers] body=[$stream_response]"
fi

tools_http_status="$(
  curl -sS -o /tmp/moe-openai-gateway-tools.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"gateway-auto","messages":[{"role":"user","content":"hello"}],"tools":[{"type":"function","function":{"name":"write_file","description":"must not run","parameters":{"type":"object","properties":{}}}}],"tool_choice":"auto","parallel_tool_calls":true,"response_format":{"type":"text"},"top_p":0.9,"n":1,"user":"continue"}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
tools_response="$(cat /tmp/moe-openai-gateway-tools.json 2>/dev/null || true)"

if [ "$tools_http_status" = "200" ] \
  && [ "$(jq -r '.choices[0].message.content // empty' <<<"$tools_response")" != "" ] \
  && [ "$(jq -r '.x_gateway_compat.tools_ignored' <<<"$tools_response")" = "true" ] \
  && [ "$(jq -r '.x_gateway_compat.tool_choice_ignored' <<<"$tools_response")" = "true" ]; then
  pass "Gateway OpenAI /v1/chat/completions ignores tool payloads"
else
  fail "Gateway OpenAI expected HTTP 200 for ignored tool payloads, got $tools_http_status: $tools_response"
fi

invalid_http_status="$(
  curl -sS -o /tmp/moe-openai-gateway-invalid.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"gateway-auto","messages":[]}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
invalid_response="$(cat /tmp/moe-openai-gateway-invalid.json 2>/dev/null || true)"

if [ "$invalid_http_status" = "400" ] \
  && [ "$(jq -r '.error.message // empty' <<<"$invalid_response")" != "" ] \
  && [ "$(jq -r '.error.type // empty' <<<"$invalid_response")" = "invalid_request_error" ] \
  && [ "$(jq -r '.error.code // empty' <<<"$invalid_response")" = "invalid_request" ]; then
  pass "Gateway OpenAI /v1/chat/completions returns JSON error bodies"
else
  fail "Gateway OpenAI expected JSON error body for invalid messages, got $invalid_http_status: $invalid_response"
fi

echo "Gateway OpenAI-compatible test passed"
