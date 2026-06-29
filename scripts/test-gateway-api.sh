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

if ! model_routing_response="$(curl -fsS "$GATEWAY_API_URL/gateway/model-routing")"; then
  fail "Gateway API /gateway/model-routing request failed"
fi

model_routing_status="$(jq -r '.status // empty' <<<"$model_routing_response")"
model_routing_default="$(jq -r '.default_model_target // empty' <<<"$model_routing_response")"
model_routing_intents_type="$(jq -r 'if (.intent_model_targets | type) == "object" then "object" else "other" end' <<<"$model_routing_response")"

if [ "$model_routing_status" = "ok" ] \
  && [ -n "$model_routing_default" ] \
  && [ "$model_routing_intents_type" = "object" ]; then
  pass "Gateway API /gateway/model-routing"
else
  fail "Gateway API /gateway/model-routing returned unexpected response: $model_routing_response"
fi

if ! runtime_status_response="$(curl -fsS "$GATEWAY_API_URL/gateway/runtime/status")"; then
  fail "Gateway API /gateway/runtime/status request failed"
fi

runtime_status="$(jq -r '.status // empty' <<<"$runtime_status_response")"
runtime_available="$(jq -r '.runtime_available' <<<"$runtime_status_response")"
runtime_models_type="$(jq -r 'if (.loaded_models | type) == "array" then "array" else "other" end' <<<"$runtime_status_response")"

if [ "$runtime_status" = "ok" ] \
  && { [ "$runtime_available" = "true" ] || [ "$runtime_available" = "false" ]; } \
  && [ "$runtime_models_type" = "array" ]; then
  pass "Gateway API /gateway/runtime/status"
else
  fail "Gateway API /gateway/runtime/status returned unexpected response: $runtime_status_response"
fi

assert_switch_plan() {
  local message="$1"
  local expected_target="$2"
  local body
  local response
  local plan_status
  local plan_target
  local manual_command

  body="$(jq -nc --arg message "$message" '{message: $message}')"
  if ! response="$(post_json "/gateway/runtime/switch-plan" "$body")"; then
    fail "Gateway API /gateway/runtime/switch-plan request failed for: $message"
  fi

  plan_status="$(jq -r '.status // empty' <<<"$response")"
  plan_target="$(jq -r '.target // empty' <<<"$response")"
  manual_command="$(jq -r '.manual_command // empty' <<<"$response")"

  if [ "$plan_status" = "ok" ] \
    && [ "$plan_target" = "$expected_target" ] \
    && [ -n "$manual_command" ]; then
    pass "Gateway API /gateway/runtime/switch-plan target=$expected_target"
  else
    fail "Gateway API /gateway/runtime/switch-plan expected $expected_target, got: $response"
  fi
}

assert_switch_plan "review this architecture for risks" "qwen-coder-32b-main"
assert_switch_plan "docker compose port issue" "deepseek-coder-lite"

assert_route_intent() {
  local message="$1"
  local expected_intent="$2"
  local expected_model_target="$3"
  local body
  local response
  local route_status
  local route_intent
  local route_model_target
  local route_runtime_id
  local route_mapping_status
  local route_confidence
  local route_reason
  local route_memory_enabled
  local route_keywords_type
  local route_message_length

  body="$(jq -nc --arg message "$message" '{message: $message, use_memory: false}')"
  if ! response="$(post_json "/gateway/route" "$body")"; then
    fail "Gateway API /gateway/route request failed for: $message"
  fi

  route_status="$(jq -r '.status // empty' <<<"$response")"
  route_intent="$(jq -r '.intent // empty' <<<"$response")"
  route_model_target="$(jq -r '.model_target // empty' <<<"$response")"
  route_runtime_id="$(jq -r '.model_target_runtime_id // empty' <<<"$response")"
  route_mapping_status="$(jq -r '.model_mapping_status // empty' <<<"$response")"
  route_confidence="$(jq -r '.confidence // empty' <<<"$response")"
  route_reason="$(jq -r '.reason // empty' <<<"$response")"
  route_memory_enabled="$(jq -r '.memory_enabled' <<<"$response")"
  route_keywords_type="$(jq -r 'if (.signals.matched_keywords | type) == "array" then "array" else "other" end' <<<"$response")"
  route_message_length="$(jq -r '.signals.message_length // empty' <<<"$response")"

  if [ "$route_status" = "ok" ] \
    && [ "$route_intent" = "$expected_intent" ] \
    && [ "$route_model_target" = "$expected_model_target" ] \
    && [ -n "$route_runtime_id" ] \
    && [ "$route_mapping_status" = "mapped" ] \
    && [ -n "$route_confidence" ] \
    && [ -n "$route_reason" ] \
    && [ "$route_memory_enabled" = "false" ] \
    && [ "$route_keywords_type" = "array" ] \
    && [ -n "$route_message_length" ]; then
    pass "Gateway API /gateway/route intent=$expected_intent"
  else
    fail "Gateway API /gateway/route expected $expected_intent, got: $response"
  fi
}

assert_route_intent "hello how are you" "chat" "qwen-coder-14b-fast"
assert_route_intent "fix this python traceback error" "code" "qwen-coder-14b-fast"
assert_route_intent "what do you remember about my local AI runtime?" "memory" "qwen-coder-14b-fast"
assert_route_intent "review this architecture for security risks" "review" "qwen-coder-32b-main"
assert_route_intent "docker compose service cannot reach localhost port" "ops" "deepseek-coder-lite"

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

if [ "${RUN_GATEWAY_CHAT_ROUTER_TEST:-0}" = "1" ]; then
  if ! router_code_response="$(post_json "/gateway/chat" '{"message":"fix this python traceback error","auto_route":true,"use_memory":false,"temperature":0.2,"max_tokens":128}')"; then
    fail "Gateway API /gateway/chat router code request failed"
  fi

  router_code_status="$(jq -r '.status // empty' <<<"$router_code_response")"
  router_code_intent="$(jq -r '.route.intent // empty' <<<"$router_code_response")"
  router_code_target="$(jq -r '.route.model_target // empty' <<<"$router_code_response")"
  router_code_alignment_actual="$(jq -r '.model_alignment.actual // empty' <<<"$router_code_response")"
  router_code_content="$(jq -r '.content // empty' <<<"$router_code_response")"

  if [ "$router_code_status" = "ok" ] \
    && [ "$router_code_intent" = "code" ] \
    && [ "$router_code_target" = "qwen-coder-14b-fast" ] \
    && [ -n "$router_code_alignment_actual" ] \
    && [ -n "$router_code_content" ]; then
    pass "Gateway API /gateway/chat router code"
  else
    fail "Gateway API /gateway/chat router code returned unexpected response: $router_code_response"
  fi

  if ! router_memory_response="$(post_json "/gateway/chat" '{"message":"what do you remember about my local AI runtime?","auto_route":true,"temperature":0.2,"max_tokens":128}')"; then
    fail "Gateway API /gateway/chat router memory request failed"
  fi

  router_memory_status="$(jq -r '.status // empty' <<<"$router_memory_response")"
  router_memory_intent="$(jq -r '.route.intent // empty' <<<"$router_memory_response")"
  router_memory_target="$(jq -r '.route.model_target // empty' <<<"$router_memory_response")"
  router_memory_alignment_actual="$(jq -r '.model_alignment.actual // empty' <<<"$router_memory_response")"
  router_memory_enabled="$(jq -r '.memory.enabled' <<<"$router_memory_response")"
  router_memory_memory_status="$(jq -r '.memory.status // empty' <<<"$router_memory_response")"
  router_memory_content="$(jq -r '.content // empty' <<<"$router_memory_response")"

  if [ "$router_memory_status" = "ok" ] \
    && [ "$router_memory_intent" = "memory" ] \
    && [ "$router_memory_target" = "qwen-coder-14b-fast" ] \
    && [ -n "$router_memory_alignment_actual" ] \
    && [ "$router_memory_enabled" = "true" ] \
    && [ -n "$router_memory_memory_status" ] \
    && [ -n "$router_memory_content" ]; then
    pass "Gateway API /gateway/chat router memory"
  else
    fail "Gateway API /gateway/chat router memory returned unexpected response: $router_memory_response"
  fi
fi

echo "Gateway API tests passed"
