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

openai_chat_http_status="$(
  curl -sS -o /tmp/moe-gateway-openai-chat-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"local-gateway","messages":[{"role":"system","content":"You are concise."},{"role":"user","content":"Return only OK."}],"temperature":0.2,"max_tokens":16,"stream":false}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"
openai_chat_response="$(cat /tmp/moe-gateway-openai-chat-response.json 2>/dev/null || true)"

case "$openai_chat_http_status" in
  200)
    openai_chat_object="$(jq -r '.object // empty' <<<"$openai_chat_response")"
    openai_chat_choices_type="$(jq -r 'if (.choices | type) == "array" then "array" else "other" end' <<<"$openai_chat_response")"
    if [ "$openai_chat_object" = "chat.completion" ] && [ "$openai_chat_choices_type" = "array" ]; then
      pass "Gateway API /v1/chat/completions"
    else
      fail "Gateway API /v1/chat/completions returned unexpected response: $openai_chat_response"
    fi
    ;;
  503)
    openai_chat_detail="$(jq -r '.detail // empty' <<<"$openai_chat_response")"
    if [ -n "$openai_chat_detail" ]; then
      pass "Gateway API /v1/chat/completions controlled unavailable"
    else
      fail "Gateway API /v1/chat/completions missing unavailable detail: $openai_chat_response"
    fi
    ;;
  *)
    fail "Gateway API /v1/chat/completions returned HTTP $openai_chat_http_status: $openai_chat_response"
    ;;
esac

openai_stream_http_status="$(
  curl -sS -o /tmp/moe-gateway-openai-stream-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"model":"local-gateway","messages":[{"role":"user","content":"hello"}],"stream":true}' \
    "$GATEWAY_API_URL/v1/chat/completions" || true
)"

if [ "$openai_stream_http_status" = "400" ]; then
  pass "Gateway API /v1/chat/completions rejects streaming"
else
  openai_stream_response="$(cat /tmp/moe-gateway-openai-stream-response.json 2>/dev/null || true)"
  fail "Gateway API /v1/chat/completions expected HTTP 400 for stream=true, got $openai_stream_http_status: $openai_stream_response"
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

if ! tools_response="$(curl -fsS "$GATEWAY_API_URL/gateway/tools")"; then
  fail "Gateway API /gateway/tools request failed"
fi

tools_status="$(jq -r '.status // empty' <<<"$tools_response")"
tools_auto_execution="$(jq -r '.auto_execution_enabled' <<<"$tools_response")"
tools_read_only_execution="$(jq -r '.read_only_execution_enabled' <<<"$tools_response")"
tools_model_chat="$(jq -r 'if .tools.model_chat then "present" else "missing" end' <<<"$tools_response")"
tools_memory_search="$(jq -r 'if .tools.memory_search then "present" else "missing" end' <<<"$tools_response")"
tools_runtime_switch_plan="$(jq -r 'if .tools.runtime_switch_plan then "present" else "missing" end' <<<"$tools_response")"
tools_docker_status_check="$(jq -r 'if .tools.docker_status_check then "present" else "missing" end' <<<"$tools_response")"
tools_shell_command_suggestion="$(jq -r 'if .tools.shell_command_suggestion then "present" else "missing" end' <<<"$tools_response")"
tools_gateway_health_check="$(jq -r 'if .tools.gateway_health_check then "present" else "missing" end' <<<"$tools_response")"
tools_memory_deep_health_check="$(jq -r 'if .tools.memory_deep_health_check then "present" else "missing" end' <<<"$tools_response")"
tools_runtime_status_check="$(jq -r 'if .tools.runtime_status_check then "present" else "missing" end' <<<"$tools_response")"
tools_workspace_status="$(jq -r 'if .tools.workspace_status then "present" else "missing" end' <<<"$tools_response")"
tools_code_context="$(jq -r 'if .tools.code_context then "present" else "missing" end' <<<"$tools_response")"
tools_code_ask="$(jq -r 'if .tools.code_ask then "present" else "missing" end' <<<"$tools_response")"
tools_code_patch_plan="$(jq -r 'if .tools.code_patch_plan then "present" else "missing" end' <<<"$tools_response")"
tools_code_diff_suggest="$(jq -r 'if .tools.code_diff_suggest then "present" else "missing" end' <<<"$tools_response")"

if [ "$tools_status" = "ok" ] \
  && [ "$tools_auto_execution" = "false" ] \
  && [ "$tools_read_only_execution" = "true" ] \
  && [ "$tools_model_chat" = "present" ] \
  && [ "$tools_memory_search" = "present" ] \
  && [ "$tools_runtime_switch_plan" = "present" ] \
  && [ "$tools_docker_status_check" = "present" ] \
  && [ "$tools_shell_command_suggestion" = "present" ] \
  && [ "$tools_gateway_health_check" = "present" ] \
  && [ "$tools_memory_deep_health_check" = "present" ] \
  && [ "$tools_runtime_status_check" = "present" ] \
  && [ "$tools_workspace_status" = "present" ] \
  && [ "$tools_code_context" = "present" ] \
  && [ "$tools_code_ask" = "present" ] \
  && [ "$tools_code_patch_plan" = "present" ] \
  && [ "$tools_code_diff_suggest" = "present" ]; then
  pass "Gateway API /gateway/tools"
else
  fail "Gateway API /gateway/tools returned unexpected response: $tools_response"
fi

assert_tool_execute_ok() {
  local tool="$1"
  local arguments

  if [ "$#" -ge 2 ]; then
    arguments="$2"
  else
    arguments='{}'
  fi
  local payload
  local response
  local status

  if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$arguments"; then
    fail "Invalid JSON object for /gateway/tools/execute arguments for $tool: $arguments"
  fi

  payload="$(jq -n --arg tool "$tool" --argjson arguments "$arguments" \
    '{tool:$tool, arguments:$arguments}')"

  if ! response="$(post_json "/gateway/tools/execute" "$payload")"; then
    fail "Gateway API /gateway/tools/execute $tool request failed"
  fi

  status="$(jq -r '.status // empty' <<<"$response")"

  if [ "$status" = "ok" ]; then
    pass "Gateway API /gateway/tools/execute $tool"
  else
    fail "Gateway API /gateway/tools/execute $tool returned unexpected response: $response"
  fi
}

assert_tool_execute_rejected() {
  local tool="$1"
  local arguments

  if [ "$#" -ge 2 ]; then
    arguments="$2"
  else
    arguments='{}'
  fi
  local payload
  local response
  local status

  if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$arguments"; then
    fail "Invalid JSON object for /gateway/tools/execute arguments for $tool: $arguments"
  fi

  payload="$(jq -n --arg tool "$tool" --argjson arguments "$arguments" \
    '{tool:$tool, arguments:$arguments}')"

  if ! response="$(post_json "/gateway/tools/execute" "$payload")"; then
    fail "Gateway API /gateway/tools/execute $tool request failed"
  fi

  status="$(jq -r '.status // empty' <<<"$response")"

  if [ "$status" = "rejected" ]; then
    pass "Gateway API /gateway/tools/execute rejects $tool"
  else
    fail "Gateway API /gateway/tools/execute $tool returned unexpected response: $response"
  fi
}

assert_tool_execute_error() {
  local tool="$1"
  local arguments

  if [ "$#" -ge 2 ]; then
    arguments="$2"
  else
    arguments='{}'
  fi
  local payload
  local response
  local status

  if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$arguments"; then
    fail "Invalid JSON object for /gateway/tools/execute arguments for $tool: $arguments"
  fi

  payload="$(jq -n --arg tool "$tool" --argjson arguments "$arguments" \
    '{tool:$tool, arguments:$arguments}')"

  if ! response="$(post_json "/gateway/tools/execute" "$payload")"; then
    fail "Gateway API /gateway/tools/execute $tool request failed"
  fi

  status="$(jq -r '.status // empty' <<<"$response")"

  if [ "$status" = "error" ]; then
    pass "Gateway API /gateway/tools/execute unknown $tool"
  else
    fail "Gateway API /gateway/tools/execute $tool returned unexpected response: $response"
  fi
}

assert_tool_execute_ok "gateway_health_check" '{}'
assert_tool_execute_ok "memory_health_check" '{}'
assert_tool_execute_ok "memory_deep_health_check" '{}'
assert_tool_execute_ok "embed_worker_health_check" '{}'
assert_tool_execute_ok "runtime_status_check" '{}'
assert_tool_execute_ok "model_routing_read" '{}'
assert_tool_execute_ok "tools_read" '{}'
assert_tool_execute_ok "workspace_status" '{}'
assert_tool_execute_ok "workspace_tree" '{"path":".","max_items":20}'
assert_tool_execute_ok "workspace_search" '{"query":"gateway","path":".","max_results":5}'
assert_tool_execute_ok "workspace_file_read" '{"path":"docs/gateway-api.md"}'
assert_tool_execute_ok "workspace_context" '{"task":"explain gateway docs","paths":["docs/gateway-api.md"],"max_chars":4000}'
assert_tool_execute_ok "code_context" '{"task":"explain gateway routing","query":"gateway","paths":[],"max_files":4,"max_chars":8000}'
assert_tool_execute_ok "code_patch_plan" '{"task":"Suggest a docs-only change","query":"gateway","paths":["docs/gateway-api.md"],"max_files":2,"max_context_chars":4000,"max_tokens":128}'
assert_tool_execute_ok "code_diff_suggest" '{"task":"Suggest a docs-only diff","query":"gateway","paths":["docs/gateway-api.md"],"max_files":2,"max_context_chars":4000,"max_tokens":128}'
assert_tool_execute_rejected "shell_command_suggestion"
assert_tool_execute_rejected "docker_status_check"
assert_tool_execute_rejected "runtime_switch_plan"
assert_tool_execute_rejected "model_chat"
assert_tool_execute_rejected "memory_search"
assert_tool_execute_rejected "none"
assert_tool_execute_error "unknown_tool"

if ! workspace_status_response="$(curl -fsS "$GATEWAY_API_URL/gateway/workspace/status")"; then
  fail "Gateway API /gateway/workspace/status request failed"
fi

workspace_status="$(jq -r '.status // empty' <<<"$workspace_status_response")"
workspace_read_only="$(jq -r '.read_only' <<<"$workspace_status_response")"

if [ "$workspace_status" = "ok" ] && [ "$workspace_read_only" = "true" ]; then
  pass "Gateway API /gateway/workspace/status"
else
  fail "Gateway API /gateway/workspace/status returned unexpected response: $workspace_status_response"
fi

if ! workspace_tree_response="$(curl -fsS "$GATEWAY_API_URL/gateway/workspace/tree?max_items=20")"; then
  fail "Gateway API /gateway/workspace/tree request failed"
fi

workspace_tree_status="$(jq -r '.status // empty' <<<"$workspace_tree_response")"
workspace_tree_items_type="$(jq -r 'if (.items | type) == "array" then "array" else "other" end' <<<"$workspace_tree_response")"

if [ "$workspace_tree_status" = "ok" ] && [ "$workspace_tree_items_type" = "array" ]; then
  pass "Gateway API /gateway/workspace/tree"
else
  fail "Gateway API /gateway/workspace/tree returned unexpected response: $workspace_tree_response"
fi

if ! workspace_file_response="$(curl -fsS "$GATEWAY_API_URL/gateway/workspace/file?path=docs/gateway-api.md")"; then
  fail "Gateway API /gateway/workspace/file request failed"
fi

workspace_file_status="$(jq -r '.status // empty' <<<"$workspace_file_response")"
workspace_file_path="$(jq -r '.path // empty' <<<"$workspace_file_response")"
workspace_file_content="$(jq -r '.content // empty' <<<"$workspace_file_response")"

if [ "$workspace_file_status" = "ok" ] \
  && [ "$workspace_file_path" = "docs/gateway-api.md" ] \
  && [ -n "$workspace_file_content" ]; then
  pass "Gateway API /gateway/workspace/file"
else
  fail "Gateway API /gateway/workspace/file returned unexpected response: $workspace_file_response"
fi

if ! workspace_rejected_response="$(curl -fsS -G --data-urlencode "path=../../etc/passwd" "$GATEWAY_API_URL/gateway/workspace/file")"; then
  fail "Gateway API /gateway/workspace/file traversal request failed"
fi

workspace_rejected_status="$(jq -r '.status // empty' <<<"$workspace_rejected_response")"

if [ "$workspace_rejected_status" = "rejected" ]; then
  pass "Gateway API /gateway/workspace/file rejects traversal"
else
  fail "Gateway API /gateway/workspace/file traversal returned unexpected response: $workspace_rejected_response"
fi

if ! workspace_search_response="$(post_json "/gateway/workspace/search" '{"query":"gateway","path":"docs","max_results":5}')"; then
  fail "Gateway API /gateway/workspace/search request failed"
fi

workspace_search_status="$(jq -r '.status // empty' <<<"$workspace_search_response")"
workspace_search_results_type="$(jq -r 'if (.results | type) == "array" then "array" else "other" end' <<<"$workspace_search_response")"

if [ "$workspace_search_status" = "ok" ] && [ "$workspace_search_results_type" = "array" ]; then
  pass "Gateway API /gateway/workspace/search"
else
  fail "Gateway API /gateway/workspace/search returned unexpected response: $workspace_search_response"
fi

if ! workspace_context_response="$(post_json "/gateway/workspace/context" '{"task":"explain gateway docs","paths":["docs/gateway-api.md"],"max_chars":4000}')"; then
  fail "Gateway API /gateway/workspace/context request failed"
fi

workspace_context_status="$(jq -r '.status // empty' <<<"$workspace_context_response")"
workspace_context_text="$(jq -r '.context // empty' <<<"$workspace_context_response")"
workspace_context_files_type="$(jq -r 'if (.files | type) == "array" then "array" else "other" end' <<<"$workspace_context_response")"

if [ "$workspace_context_status" = "ok" ] \
  && [ -n "$workspace_context_text" ] \
  && [ "$workspace_context_files_type" = "array" ]; then
  pass "Gateway API /gateway/workspace/context"
else
  fail "Gateway API /gateway/workspace/context returned unexpected response: $workspace_context_response"
fi

if ! code_context_response="$(post_json "/gateway/code/context" '{"task":"explain how gateway routing works","query":"gateway","paths":[],"max_files":8,"max_chars":20000}')"; then
  fail "Gateway API /gateway/code/context request failed"
fi

code_context_status="$(jq -r '.status // empty' <<<"$code_context_response")"
code_context_files_count="$(jq -r '.selected_files | length' <<<"$code_context_response")"
code_context_text="$(jq -r '.context // empty' <<<"$code_context_response")"

if [ "$code_context_status" = "ok" ] \
  && [ "$code_context_files_count" -gt 0 ] \
  && [ -n "$code_context_text" ]; then
  pass "Gateway API /gateway/code/context"
else
  fail "Gateway API /gateway/code/context returned unexpected response: $code_context_response"
fi

if ! code_context_traversal_response="$(post_json "/gateway/code/context" '{"task":"check traversal safety","query":null,"paths":["../../etc/passwd"],"max_files":8,"max_chars":4000}')"; then
  fail "Gateway API /gateway/code/context traversal request failed"
fi

code_context_traversal_status="$(jq -r '.status // empty' <<<"$code_context_traversal_response")"
code_context_traversal_files_count="$(jq -r '.selected_files | length' <<<"$code_context_traversal_response")"

if [ "$code_context_traversal_status" = "ok" ] \
  && [ "$code_context_traversal_files_count" -eq 0 ]; then
  pass "Gateway API /gateway/code/context skips traversal path"
else
  fail "Gateway API /gateway/code/context traversal returned unexpected response: $code_context_traversal_response"
fi

code_ask_http_status="$(
  curl -sS -o /tmp/moe-gateway-code-ask-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"task":"explain how gateway routing works","query":"gateway","paths":[],"max_files":4,"max_context_chars":8000,"temperature":0.1,"max_tokens":128,"use_memory":false,"auto_route":true}' \
    "$GATEWAY_API_URL/gateway/code/ask" || true
)"
code_ask_response="$(cat /tmp/moe-gateway-code-ask-response.json 2>/dev/null || true)"
code_ask_status="$(jq -r '.status // empty' <<<"$code_ask_response")"

case "$code_ask_http_status" in
  200)
    if [ "$code_ask_status" = "ok" ] || [ "$code_ask_status" = "unavailable" ]; then
      pass "Gateway API /gateway/code/ask controlled response"
    else
      fail "Gateway API /gateway/code/ask returned unexpected response: $code_ask_response"
    fi
    ;;
  *)
    fail "Gateway API /gateway/code/ask expected controlled HTTP 200, got $code_ask_http_status: $code_ask_response"
    ;;
esac

patch_plan_http_status="$(
  curl -sS -o /tmp/moe-gateway-code-patch-plan-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"task":"Add validation for missing query in workspace search","query":"workspace search","paths":["apps/gateway-api/app/main.py","apps/gateway-api/app/services/workspace.py"],"max_files":8,"max_context_chars":12000,"temperature":0.1,"max_tokens":256}' \
    "$GATEWAY_API_URL/gateway/code/patch-plan" || true
)"
patch_plan_response="$(cat /tmp/moe-gateway-code-patch-plan-response.json 2>/dev/null || true)"
patch_plan_status="$(jq -r '.status // empty' <<<"$patch_plan_response")"

case "$patch_plan_http_status" in
  200)
    if [ "$patch_plan_status" = "ok" ] || [ "$patch_plan_status" = "unavailable" ]; then
      pass "Gateway API /gateway/code/patch-plan controlled response"
    else
      fail "Gateway API /gateway/code/patch-plan returned unexpected response: $patch_plan_response"
    fi
    ;;
  *)
    fail "Gateway API /gateway/code/patch-plan expected controlled HTTP 200, got $patch_plan_http_status: $patch_plan_response"
    ;;
esac

diff_suggest_http_status="$(
  curl -sS -o /tmp/moe-gateway-code-diff-suggest-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"task":"Add validation for missing query in workspace search","query":"workspace search","paths":["apps/gateway-api/app/main.py","apps/gateway-api/app/services/workspace.py"],"max_files":8,"max_context_chars":12000,"temperature":0.1,"max_tokens":256}' \
    "$GATEWAY_API_URL/gateway/code/diff-suggest" || true
)"
diff_suggest_response="$(cat /tmp/moe-gateway-code-diff-suggest-response.json 2>/dev/null || true)"
diff_suggest_status="$(jq -r '.status // empty' <<<"$diff_suggest_response")"
diff_suggest_apply_supported="$(jq -r '.apply_supported' <<<"$diff_suggest_response")"

case "$diff_suggest_http_status" in
  200)
    if { [ "$diff_suggest_status" = "ok" ] || [ "$diff_suggest_status" = "unavailable" ]; } \
      && [ "$diff_suggest_apply_supported" = "false" ]; then
      pass "Gateway API /gateway/code/diff-suggest controlled response"
    else
      fail "Gateway API /gateway/code/diff-suggest returned unexpected response: $diff_suggest_response"
    fi
    ;;
  *)
    fail "Gateway API /gateway/code/diff-suggest expected controlled HTTP 200, got $diff_suggest_http_status: $diff_suggest_response"
    ;;
esac

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
  local expected_tool="$4"
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
  local route_tool_plan_type
  local route_tool_match

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
  route_tool_plan_type="$(jq -r 'if (.tool_plan.recommended_tools | type) == "array" then "array" else "other" end' <<<"$response")"
  route_tool_match="$(jq -r --arg tool "$expected_tool" 'if (.tool_plan.recommended_tools | index($tool)) then "present" else "missing" end' <<<"$response")"

  if [ "$route_status" = "ok" ] \
    && [ "$route_intent" = "$expected_intent" ] \
    && [ "$route_model_target" = "$expected_model_target" ] \
    && [ -n "$route_runtime_id" ] \
    && [ "$route_mapping_status" = "mapped" ] \
    && [ -n "$route_confidence" ] \
    && [ -n "$route_reason" ] \
    && [ "$route_memory_enabled" = "false" ] \
    && [ "$route_keywords_type" = "array" ] \
    && [ -n "$route_message_length" ] \
    && [ "$route_tool_plan_type" = "array" ] \
    && [ "$route_tool_match" = "present" ]; then
    pass "Gateway API /gateway/route intent=$expected_intent"
  else
    fail "Gateway API /gateway/route expected $expected_intent, got: $response"
  fi
}

assert_route_intent "hello how are you" "chat" "qwen-coder-14b-fast" "model_chat"
assert_route_intent "fix this python traceback error" "code" "qwen-coder-14b-fast" "code_context"
assert_route_intent "what do you remember about my local AI runtime?" "memory" "qwen-coder-14b-fast" "memory_search"
assert_route_intent "review this architecture for security risks" "review" "qwen-coder-32b-main" "runtime_switch_plan"
assert_route_intent "docker compose service cannot reach localhost port" "ops" "deepseek-coder-lite" "docker_status_check"

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
