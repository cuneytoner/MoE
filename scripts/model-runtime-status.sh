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
LOG_FILE="${MODEL_RUNTIME_LOG_FILE:-$(runtime_value log_file)}"

endpoint_status() {
  local response

  if ! command -v curl >/dev/null 2>&1; then
    echo "not checked (curl missing)"
    return 1
  fi

  if response="$(curl -fsS --connect-timeout 1 --max-time 2 "$OPENAI_BASE_URL/models" 2>/dev/null)"; then
    if command -v jq >/dev/null 2>&1; then
      if jq -e '.data | type == "array"' >/dev/null 2>&1 <<<"$response"; then
        echo "ready"
        return 0
      fi
      echo "reachable but unexpected response"
      return 1
    fi

    echo "reachable (jq missing; JSON not validated)"
    return 0
  fi

  echo "unavailable"
  return 1
}

if [ -f "$METADATA_FILE" ]; then
  # shellcheck disable=SC1090
  source "$METADATA_FILE"
fi

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE")"
  if [ -z "$PID" ]; then
    echo "Status: stale pid file"
    echo "PID: unknown"
    echo "Cleanup: make model-stop"
  elif ! kill -0 "$PID" >/dev/null 2>&1; then
    echo "Status: stale pid file"
    echo "PID: $PID"
    echo "Cleanup: make model-stop"
  else
    PROCESS_STAT="$(ps -p "$PID" -o stat= 2>/dev/null | awk '{print $1}' || true)"
    PROCESS_ARGS="$(ps -p "$PID" -o args= 2>/dev/null || true)"

    if [[ "$PROCESS_STAT" == *Z* ]]; then
      echo "Status: stale pid file (zombie process)"
      echo "PID: $PID"
      echo "Cleanup: make model-stop"
    elif [[ "$PROCESS_ARGS" != *llama-server* ]]; then
      echo "Status: stale pid file (pid is not llama-server)"
      echo "PID: $PID"
      echo "Process: ${PROCESS_ARGS:-unknown}"
      echo "Cleanup: make model-stop"
    else
      ENDPOINT_STATUS="$(endpoint_status || true)"
      if [ "$ENDPOINT_STATUS" = "ready" ]; then
        echo "Status: running"
      else
        echo "Status: process exists but endpoint unavailable"
      fi
      echo "PID: $PID"
      echo "Endpoint status: $ENDPOINT_STATUS"
    fi
  fi
else
  echo "Status: stopped"
fi

echo "Endpoint: ${OPENAI_BASE_URL:-$(runtime_value openai_base_url)}"
echo "Model: ${MODEL_ID:-unknown}"
echo "Log: ${LOG_FILE:-unknown}"
