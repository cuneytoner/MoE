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

health_backend="$(jq -r '.backend' <<<"$health_response")"
if [ "$health_backend" = "bge-m3" ]; then
  pass "Embed Worker /health backend is bge-m3"
else
  fail "Expected embed-worker backend bge-m3, got: $health_backend"
fi

if ! embed_response="$(post_json "/embed" '{"text":"hello world"}')"; then
  fail "Embed Worker bge-m3 /embed request failed"
fi

embed_status="$(jq -r '.status' <<<"$embed_response")"
embed_backend="$(jq -r '.backend' <<<"$embed_response")"
embed_dim="$(jq -r '.embedding_dim' <<<"$embed_response")"
vector_length="$(jq -r '.vector | length' <<<"$embed_response")"

if [ "$embed_status" = "ok" ] && [ "$embed_backend" = "bge-m3" ]; then
  pass "Embed Worker bge-m3 /embed status"
else
  fail "Embed Worker bge-m3 /embed returned unexpected response: $embed_response"
fi

if [ "$embed_dim" -gt 0 ] && [ "$embed_dim" = "$vector_length" ]; then
  pass "Embed Worker bge-m3 vector length matches embedding_dim"
else
  fail "Invalid BGE-M3 vector length: embedding_dim=$embed_dim vector_length=$vector_length"
fi

echo "INFO: Detected BGE-M3 embedding dimension: $embed_dim"
echo "BGE-M3 runtime test passed"
