#!/usr/bin/env bash
set -euo pipefail

EMBED_WORKER_URL="${EMBED_WORKER_URL:-http://localhost:8102}"

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

post_json() {
  local path="$1"
  local body="$2"

  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$body" \
    "$EMBED_WORKER_URL$path"
}

require_command curl
require_command jq

if ! health_response="$(curl -fsS "$EMBED_WORKER_URL/health")"; then
  fail "Embed Worker /health request failed"
fi

health_service="$(jq -r '.service' <<<"$health_response")"
health_status="$(jq -r '.status' <<<"$health_response")"
health_backend="$(jq -r '.backend' <<<"$health_response")"
health_dim="$(jq -r '.embedding_dim' <<<"$health_response")"

if [ "$health_service" = "embed-worker" ] && [ "$health_status" = "ok" ] && [ "$health_backend" = "fake" ]; then
  pass "Embed Worker /health"
else
  fail "Embed Worker /health returned unexpected response: $health_response"
fi

if [ "$health_dim" = "384" ]; then
  pass "Embed Worker default embedding_dim"
else
  fail "Expected embedding_dim 384, got: $health_dim"
fi

if ! embed_response="$(post_json "/embed" '{"text":"hello world"}')"; then
  fail "Embed Worker /embed request failed"
fi

embed_status="$(jq -r '.status' <<<"$embed_response")"
embed_dim="$(jq -r '.embedding_dim' <<<"$embed_response")"
vector_length="$(jq -r '.vector | length' <<<"$embed_response")"

if [ "$embed_status" = "ok" ]; then
  pass "Embed Worker /embed status"
else
  fail "Embed Worker /embed returned unexpected response: $embed_response"
fi

if [ "$embed_dim" = "384" ] && [ "$vector_length" = "$embed_dim" ]; then
  pass "Embed Worker vector length"
else
  fail "Expected vector length $embed_dim, got: $vector_length"
fi

echo "Embed Worker tests passed"
