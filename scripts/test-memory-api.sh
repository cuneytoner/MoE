#!/usr/bin/env bash
set -euo pipefail

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

get_json() {
  local path="$1"

  curl -fsS "$MEMORY_API_URL$path"
}

post_json() {
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

wait_for_http "$MEMORY_API_URL/health" "Memory API /health"

if ! health_response="$(get_json "/health")"; then
  fail "Memory API /health request failed"
fi
health_status="$(jq -r '.status' <<<"$health_response")"
health_service="$(jq -r '.service' <<<"$health_response")"

if [ "$health_status" = "ok" ] && [ "$health_service" = "memory-api" ]; then
  pass "Memory API /health"
else
  fail "Memory API /health returned unexpected response: $health_response"
fi

if ! deep_response="$(get_json "/health/deep")"; then
  fail "Memory API /health/deep request failed"
fi
deep_status="$(jq -r '.status' <<<"$deep_response")"
deep_qdrant="$(jq -r '.dependencies.qdrant // empty' <<<"$deep_response")"
deep_embed_worker="$(jq -r '.dependencies.embed_worker // empty' <<<"$deep_response")"

case "$deep_status" in
  ok|degraded)
    pass "Memory API /health/deep"
    ;;
  *)
    fail "Memory API /health/deep returned unexpected response: $deep_response"
    ;;
esac

if [ -n "$deep_qdrant" ] && [ -n "$deep_embed_worker" ]; then
  pass "Memory API /health/deep dependencies"
else
  fail "Memory API /health/deep missing dependency details: $deep_response"
fi

if ! add_response="$(post_json "/memory/add" '{"text":"automated memory test","source":"test-memory-api","metadata":{"test":true}}')"; then
  fail "Memory API /memory/add request failed"
fi
add_status="$(jq -r '.status' <<<"$add_response")"
add_id="$(jq -r '.id // empty' <<<"$add_response")"
add_vector_id="$(jq -r '.vector_id // empty' <<<"$add_response")"
add_collection_name="$(jq -r '.collection_name // empty' <<<"$add_response")"
add_embedding_backend="$(jq -r '.embedding_backend // empty' <<<"$add_response")"
add_embedding_dim="$(jq -r '.embedding_dim // empty' <<<"$add_response")"

if [ "$add_status" = "created" ] \
  && [ -n "$add_id" ] \
  && [ -n "$add_vector_id" ] \
  && [ "$add_collection_name" = "moe_memories_fake_384" ] \
  && [ -n "$add_embedding_backend" ] \
  && [ "$add_embedding_dim" = "384" ]; then
  pass "Memory API /memory/add"
else
  fail "Memory API /memory/add returned unexpected response: $add_response"
fi

if ! search_response="$(post_json "/memory/search" '{"query":"automated memory test","limit":5}')"; then
  fail "Memory API /memory/search request failed"
fi
search_status="$(jq -r '.status' <<<"$search_response")"
search_collection_name="$(jq -r '.collection_name // empty' <<<"$search_response")"
search_embedding_backend="$(jq -r '.embedding_backend // empty' <<<"$search_response")"
search_embedding_dim="$(jq -r '.embedding_dim // empty' <<<"$search_response")"
search_results_type="$(jq -r 'if (.results | type) == "array" then "array" else "other" end' <<<"$search_response")"

if [ "$search_status" = "ok" ] \
  && [ "$search_collection_name" = "moe_memories_fake_384" ] \
  && [ -n "$search_embedding_backend" ] \
  && [ "$search_embedding_dim" = "384" ] \
  && [ "$search_results_type" = "array" ]; then
  pass "Memory API /memory/search"
else
  fail "Memory API /memory/search returned unexpected response: $search_response"
fi

echo "Memory API tests passed"
