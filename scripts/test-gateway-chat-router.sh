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
  local health_response

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

assert_router_ok() {
  local payload="$1"
  local expected_intent_a="$2"
  local expected_intent_b="${3:-$2}"
  local response

  if ! response="$(post_json "/gateway/chat" "$payload")"; then
    fail "Gateway chat router request failed"
  fi

  status="$(jq -r '.status // empty' <<<"$response")"
  if [ "$status" = "unavailable" ]; then
    detail="$(jq -r '.detail // empty' <<<"$response")"
    skip "llama-server unavailable through Gateway: $detail"
  fi

  intent="$(jq -r '.router.intent // empty' <<<"$response")"
  mode="$(jq -r '.router.mode // empty' <<<"$response")"
  selected_model_id="$(jq -r '.router.selected_model_id // empty' <<<"$response")"
  selected_model_path="$(jq -r '.router.selected_model_path // empty' <<<"$response")"
  active_model_matches="$(jq -r '.router.active_model_matches | tostring' <<<"$response")"
  reasons_type="$(jq -r 'if (.router.reasons | type) == "array" then "array" else "other" end' <<<"$response")"

  if [ "$status" = "ok" ] \
    && { [ "$intent" = "$expected_intent_a" ] || [ "$intent" = "$expected_intent_b" ]; } \
    && [ "$mode" = "advisory" ] \
    && [ -n "$selected_model_id" ] \
    && [ -n "$selected_model_path" ] \
    && { [ "$active_model_matches" = "true" ] || [ "$active_model_matches" = "false" ]; } \
    && [ "$reasons_type" = "array" ]; then
    pass "Gateway chat router intent=$intent"
  else
    fail "Gateway chat router returned unexpected response: $response"
  fi
}

require_command curl
require_command jq

if ! wait_for_gateway; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

assert_router_ok \
  '{"messages":[{"role":"user","content":"Refactor this FastAPI Docker architecture and explain the safest plan."}],"max_tokens":64,"temperature":0.2,"routing":"auto"}' \
  "architecture" \
  "deep_code"

if ! disabled_response="$(post_json "/gateway/chat" '{"messages":[{"role":"user","content":"Hello there."}],"max_tokens":32,"routing":"off"}')"; then
  fail "Gateway chat router disabled request failed"
fi

disabled_status="$(jq -r '.status // empty' <<<"$disabled_response")"
if [ "$disabled_status" = "unavailable" ]; then
  detail="$(jq -r '.detail // empty' <<<"$disabled_response")"
  skip "llama-server unavailable through Gateway: $detail"
fi

disabled_mode="$(jq -r '.router.mode // empty' <<<"$disabled_response")"
disabled_intent="$(jq -r '.router.intent // empty' <<<"$disabled_response")"
if [ "$disabled_status" = "ok" ] \
  && [ "$disabled_mode" = "disabled" ] \
  && [ "$disabled_intent" = "general" ]; then
  pass "Gateway chat router disabled mode"
else
  fail "Gateway chat router disabled mode returned unexpected response: $disabled_response"
fi

echo "Gateway chat router test passed"
