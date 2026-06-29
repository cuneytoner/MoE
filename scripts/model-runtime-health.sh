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
HEALTH_TIMEOUT="${MODEL_RUNTIME_HEALTH_TIMEOUT:-60}"
HEALTH_URL="$OPENAI_BASE_URL/models"

if ! [[ "$HEALTH_TIMEOUT" =~ ^[0-9]+$ ]] || [ "$HEALTH_TIMEOUT" -lt 1 ]; then
  fail "MODEL_RUNTIME_HEALTH_TIMEOUT must be a positive integer"
fi

START_SECONDS="$SECONDS"
LAST_ERROR="no response"

while [ "$((SECONDS - START_SECONDS))" -le "$HEALTH_TIMEOUT" ]; do
  ELAPSED="$((SECONDS - START_SECONDS))"

  if response="$(curl -fsS --connect-timeout 2 --max-time 5 "$HEALTH_URL" 2>&1)"; then
    if jq -e '.data | type == "array"' >/dev/null 2>&1 <<<"$response"; then
      echo "PASS: model runtime OpenAI-compatible endpoint is healthy"
      echo "Endpoint: $OPENAI_BASE_URL"
      echo "Waited: ${ELAPSED}s"
      exit 0
    fi
    LAST_ERROR="endpoint returned JSON without a data array"
  else
    LAST_ERROR="$(tr '\n' ' ' <<<"$response")"
  fi

  if [ "$ELAPSED" -ge "$HEALTH_TIMEOUT" ]; then
    break
  fi

  echo "Waiting for model runtime health: ${ELAPSED}s/${HEALTH_TIMEOUT}s"
  sleep 1
done

if response="$(curl -fsS --connect-timeout 2 --max-time 5 "$HEALTH_URL" 2>&1)"; then
  if jq -e '.data | type == "array"' >/dev/null 2>&1 <<<"$response"; then
    echo "PASS: model runtime OpenAI-compatible endpoint is healthy"
    echo "Endpoint: $OPENAI_BASE_URL"
    echo "Waited: $((SECONDS - START_SECONDS))s"
    exit 0
  fi
  LAST_ERROR="endpoint returned JSON without a data array"
else
  LAST_ERROR="$(tr '\n' ' ' <<<"$response")"
fi

fail "model runtime health check failed after ${HEALTH_TIMEOUT}s: $HEALTH_URL (${LAST_ERROR:-no response})"
