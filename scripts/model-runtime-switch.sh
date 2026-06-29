#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_CONFIG="$ROOT/configs/models.yaml"
RUNTIME_CONFIG="$ROOT/configs/runtime.yaml"

usage() {
  echo "Usage: scripts/model-runtime-switch.sh MODEL_ID" >&2
  exit 1
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

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

model_value() {
  local model_id="$1"
  local key="$2"

  awk -v model_id="$model_id" -v key="$key" '
    $1 == "-" && $2 == "id:" {
      in_model = ($3 == model_id)
      next
    }
    in_model && $1 == key ":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      print
      exit
    }
  ' "$MODELS_CONFIG"
}

MODEL_ID="${1:-}"
if [ -z "$MODEL_ID" ]; then
  usage
fi

MODEL_PATH="$(model_value "$MODEL_ID" path)"
if [ -z "$MODEL_PATH" ]; then
  fail "Unknown model id: $MODEL_ID"
fi

if [ ! -f "$MODEL_PATH" ]; then
  fail "Model file missing: $MODEL_PATH"
fi

MODEL_MAGIC="$(head -c 4 "$MODEL_PATH")"
if [ "$MODEL_MAGIC" != "GGUF" ]; then
  fail "invalid GGUF magic: id=$MODEL_ID path=$MODEL_PATH magic=${MODEL_MAGIC:-empty}"
fi

LOG_FILE="${MODEL_RUNTIME_LOG_FILE:-$(runtime_value log_file)}"
PID_FILE="${MODEL_RUNTIME_PID_FILE:-$(runtime_value pid_file)}"
METADATA_FILE="${MODEL_RUNTIME_METADATA_FILE:-$(runtime_value metadata_file)}"

echo "Switching model runtime to: $MODEL_ID"
echo "Model file: $MODEL_PATH"
echo "GGUF magic: $MODEL_MAGIC"

"$ROOT/scripts/model-runtime-stop.sh"
"$ROOT/scripts/model-runtime-start.sh" "$MODEL_ID"

if "$ROOT/scripts/model-runtime-health.sh"; then
  echo "Model runtime switch complete: $MODEL_ID"
  exit 0
fi

echo "Model runtime health check failed after switch."
if [ -f "$LOG_FILE" ]; then
  echo "Last 120 log lines from $LOG_FILE:"
  tail -n 120 "$LOG_FILE"
else
  echo "Runtime log file not found: $LOG_FILE"
fi

"$ROOT/scripts/model-runtime-status.sh" || true

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE")"
  if [ -z "$PID" ] || ! kill -0 "$PID" >/dev/null 2>&1; then
    echo "Removing stale pid metadata after failed switch."
    rm -f "$PID_FILE" "$METADATA_FILE"
  elif [[ "$(ps -p "$PID" -o stat= 2>/dev/null | awk '{print $1}' || true)" == *Z* ]]; then
    echo "Removing stale zombie pid metadata after failed switch."
    rm -f "$PID_FILE" "$METADATA_FILE"
  fi
fi

exit 1
