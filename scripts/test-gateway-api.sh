#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://localhost:8100}"
MEMORY_API_URL="${MEMORY_API_URL:-http://localhost:8101}"

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

wait_for_http() {
  local url="$1"
  local name="$2"
  local attempts=30

  for attempt in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  fail "$name did not become reachable within ${attempts}s: $url"
}

post_json() {
  local path="$1"
  local body="$2"

  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$body" \
    "$GATEWAY_API_URL$path"
}

post_memory_json() {
  local path="$1"
  local body="$2"

  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$body" \
    "$MEMORY_API_URL$path"
}

require_command curl
require_command jq

wait_for_http "$GATEWAY_API_URL/gateway/health" "Gateway API /gateway/health"

if ! health_response="$(curl -fsS "$GATEWAY_API_URL/gateway/health")"; then
  fail "Gateway API /gateway/health request failed"
fi

health_service="$(jq -r '.service // empty' <<<"$health_response")"
health_status="$(jq -r '.status // empty' <<<"$health_response")"
health_memory="$(jq -r '.dependencies.memory_api // empty' <<<"$health_response")"
health_embed="$(jq -r '.dependencies.embed_worker // empty' <<<"$health_response")"
health_model="$(jq -r '.dependencies.model_runtime // empty' <<<"$health_response")"

if [ "$health_service" = "gateway-api" ] && [ "$health_status" = "ok" ]; then
  pass "Gateway API /gateway/health"
else
  fail "Gateway API /gateway/health returned unexpected response: $health_response"
fi

if [ -n "$health_memory" ] && [ -n "$health_embed" ] && [ -n "$health_model" ]; then
  pass "Gateway API dependency statuses"
else
  fail "Gateway API /gateway/health missing dependency details: $health_response"
fi

models_http_status="$(
  curl -sS -o /tmp/moe-gateway-models-response.json -w "%{http_code}" \
    "$GATEWAY_API_URL/gateway/models" || true
)"
models_response="$(cat /tmp/moe-gateway-models-response.json 2>/dev/null || true)"

case "$models_http_status" in
  200)
    models_status="$(jq -r '.status // empty' <<<"$models_response")"
    models_type="$(jq -r 'if (.models | type) == "array" then "array" else "other" end' <<<"$models_response")"
    if [ "$models_status" = "ok" ] && [ "$models_type" = "array" ]; then
      pass "Gateway API /gateway/models"
    else
      fail "Gateway API /gateway/models returned unexpected response: $models_response"
    fi
    ;;
  503)
    models_detail="$(jq -r '.detail // empty' <<<"$models_response")"
    if [ -n "$models_detail" ]; then
      pass "Gateway API /gateway/models controlled unavailable"
    else
      fail "Gateway API /gateway/models missing unavailable detail: $models_response"
    fi
    ;;
  *)
    fail "Gateway API /gateway/models returned HTTP $models_http_status: $models_response"
    ;;
esac

if ! route_response="$(post_json "/gateway/route" '{"message":"hello","use_memory":false}')"; then
  fail "Gateway API /gateway/route request failed"
fi

route_status="$(jq -r '.status // empty' <<<"$route_response")"
route_intent="$(jq -r '.intent // empty' <<<"$route_response")"
route_model_target="$(jq -r '.model_target // empty' <<<"$route_response")"
route_memory_enabled="$(jq -r '.memory_enabled' <<<"$route_response")"

if [ "$route_status" = "ok" ] \
  && [ "$route_intent" = "chat" ] \
  && [ -n "$route_model_target" ] \
  && [ "$route_memory_enabled" = "false" ]; then
  pass "Gateway API /gateway/route"
else
  fail "Gateway API /gateway/route returned unexpected response: $route_response"
fi

if [ "${RUN_GATEWAY_CHAT_TEST:-0}" = "1" ]; then
  if ! chat_response="$(post_json "/gateway/chat" '{"message":"hello","temperature":0.2,"max_tokens":64}')"; then
    fail "Gateway API /gateway/chat request failed"
  fi

  chat_status="$(jq -r '.status // empty' <<<"$chat_response")"
  chat_model="$(jq -r '.model // empty' <<<"$chat_response")"
  chat_content="$(jq -r '.content // empty' <<<"$chat_response")"

  if [ "$chat_status" = "ok" ] && [ -n "$chat_model" ] && [ -n "$chat_content" ]; then
    pass "Gateway API /gateway/chat"
  else
    fail "Gateway API /gateway/chat returned unexpected response: $chat_response"
  fi
fi

if [ "${RUN_GATEWAY_CHAT_MEMORY_TEST:-0}" = "1" ]; then
  if ! post_memory_json "/memory/add" '{"text":"Cuneyt'\''s current local AI runtime model is deepseek-coder-lite.","source":"test","metadata":{"test":"gateway-memory-chat"}}' >/dev/null; then
    fail "Memory API /memory/add setup request failed"
  fi

  if ! memory_chat_response="$(post_json "/gateway/chat" '{"message":"What is my current local AI runtime model?","use_memory":true,"memory_limit":5,"temperature":0.2,"max_tokens":128}')"; then
    fail "Gateway API /gateway/chat memory request failed"
  fi

  memory_chat_status="$(jq -r '.status // empty' <<<"$memory_chat_response")"
  memory_enabled="$(jq -r '.memory.enabled' <<<"$memory_chat_response")"
  memory_status="$(jq -r '.memory.status // empty' <<<"$memory_chat_response")"
  memory_content="$(jq -r '.content // empty' <<<"$memory_chat_response")"

  if [ "$memory_chat_status" = "ok" ] \
    && [ "$memory_enabled" = "true" ] \
    && [ -n "$memory_status" ] \
    && [ -n "$memory_content" ]; then
    pass "Gateway API /gateway/chat with memory"
  else
    fail "Gateway API /gateway/chat memory returned unexpected response: $memory_chat_response"
  fi
fi

echo "Gateway API tests passed"
