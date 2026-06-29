#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_CONFIG="$ROOT/configs/runtime.yaml"

runtime_value() {
  local key="$1"

  awk -v key="$key" '
    $1 == key ":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      print
      exit
    }
  ' "$RUNTIME_CONFIG"
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

OPENAI_BASE_URL="${MODEL_RUNTIME_BASE_URL:-$(runtime_value openai_base_url)}"

if response="$(curl -fsS "$OPENAI_BASE_URL/models")"; then
  if jq -e '.data | type == "array"' >/dev/null <<<"$response"; then
    echo "PASS: model runtime OpenAI-compatible endpoint is healthy"
    echo "Endpoint: $OPENAI_BASE_URL"
    exit 0
  fi
  fail "unexpected /models response: $response"
fi

fail "model runtime health check failed: $OPENAI_BASE_URL/models"
