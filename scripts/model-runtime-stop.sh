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

if [ ! -f "$PID_FILE" ]; then
  echo "llama-server is not running: no pid file"
  exit 0
fi

PID="$(cat "$PID_FILE")"
if [ -n "$PID" ] && kill -0 "$PID" >/dev/null 2>&1; then
  kill "$PID"
  echo "Stopped llama-server pid $PID"
else
  echo "Removed stale pid file for llama-server"
fi

rm -f "$PID_FILE" "$METADATA_FILE"
