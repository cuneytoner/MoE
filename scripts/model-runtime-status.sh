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

PID_FILE="${MODEL_RUNTIME_PID_FILE:-$(runtime_value pid_file)}"
METADATA_FILE="${MODEL_RUNTIME_METADATA_FILE:-$(runtime_value metadata_file)}"
OPENAI_BASE_URL="${MODEL_RUNTIME_BASE_URL:-$(runtime_value openai_base_url)}"

if [ -f "$METADATA_FILE" ]; then
  # shellcheck disable=SC1090
  source "$METADATA_FILE"
fi

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE")"
  if [ -n "$PID" ] && kill -0 "$PID" >/dev/null 2>&1; then
    echo "Status: running"
    echo "PID: $PID"
  else
    echo "Status: stale pid file"
    echo "PID: ${PID:-unknown}"
  fi
else
  echo "Status: stopped"
fi

echo "Endpoint: ${OPENAI_BASE_URL:-$(runtime_value openai_base_url)}"
echo "Model: ${MODEL_ID:-unknown}"
