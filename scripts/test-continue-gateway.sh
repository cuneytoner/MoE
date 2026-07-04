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
router_routing_mode="$(jq -r '.x_gateway_router.routing_mode // empty' <<<"$response")"
router_runtime_switch_supported="$(jq -r '.x_gateway_router.runtime_switch_supported | tostring' <<<"$response")"
router_runtime_switch_attempted="$(jq -r '.x_gateway_router.runtime_switch_attempted | tostring' <<<"$response")"
router_continue_safe="$(jq -r '.x_gateway_router.continue_safe | tostring' <<<"$response")"
router_mismatch_level="$(jq -r '.x_gateway_router.active_model_mismatch_level // empty' <<<"$response")"
router_effective_runtime_model="$(jq -r '.x_gateway_router.effective_runtime_model // empty' <<<"$response")"
router_next_steps_type="$(jq -r 'if (.x_gateway_router.next_steps | type) == "array" then "array" else "other" end' <<<"$response")"

if [ "$status_object" = "chat.completion" ] \
  && [ -n "$content" ] \
  && [ "$router_routing_mode" = "advisory_only" ] \
  && [ "$router_runtime_switch_supported" = "false" ] \
  && [ "$router_runtime_switch_attempted" = "false" ] \
  && [ "$router_continue_safe" = "true" ] \
  && { [ "$router_mismatch_level" = "none" ] || [ "$router_mismatch_level" = "info" ] || [ "$router_mismatch_level" = "warning" ]; } \
  && [ -n "$router_effective_runtime_model" ] \
  && [ "$router_next_steps_type" = "array" ]; then
  pass "Gateway OpenAI-compatible chat for Continue.dev"
else
  fail "Gateway OpenAI-compatible chat returned unexpected response: $response"
fi

continue_headers_file="/tmp/moe-continue-gateway-stream-headers.txt"
continue_body_file="/tmp/moe-continue-gateway-stream.txt"
continue_http_status="$(
  curl -sS -D "$continue_headers_file" \
    -o "$continue_body_file" \
    -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"local-gateway","messages":[{"role":"system","content":"You are a concise local coding assistant."},{"role":"user","content":"Return only the word OK."}],"temperature":0.2,"max_tokens":16,"stream":true,"tools":[{"type":"function","function":{"name":"shell","description":"must not run","parameters":{"type":"object","properties":{}}}}],"tool_choice":"auto","parallel_tool_calls":true,"response_format":{"type":"text"},"stop":["\n\n"],"presence_penalty":0,"frequency_penalty":0,"top_p":1,"n":1,"user":"continue"}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
continue_headers="$(cat "$continue_headers_file" 2>/dev/null || true)"
continue_response="$(cat "$continue_body_file" 2>/dev/null || true)"

if [ "$continue_http_status" = "200" ] \
  && grep -qi 'content-type:.*text/event-stream' <<<"$continue_headers" \
  && grep -q 'data: ' <<<"$continue_response" \
  && grep -q '"object":"chat.completion.chunk"' <<<"$continue_response" \
  && grep -q '"choices"' <<<"$continue_response" \
  && grep -q '"stream_requested":true' <<<"$continue_response" \
  && grep -q '"stream_wrapped":true' <<<"$continue_response" \
  && grep -q '"tools_ignored":true' <<<"$continue_response" \
  && grep -q '"tool_choice_ignored":true' <<<"$continue_response" \
  && grep -q '\[DONE\]' <<<"$continue_response"; then
  pass "Gateway wraps Continue.dev stream/tool payloads as SSE without tool execution"
else
  fail "Gateway Continue-compatible payload expected HTTP 200 SSE response, got $continue_http_status headers=[$continue_headers] body=[$continue_response]"
fi
