#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_CONFIG="$ROOT/configs/models.yaml"
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

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

DEFAULT_MODEL="$(runtime_value default_model)"
MODEL_ID="${1:-$DEFAULT_MODEL}"
LLAMA_SERVER="${LLAMA_SERVER:-$(runtime_value llama_server)}"
HOST="${MODEL_RUNTIME_HOST:-$(runtime_value host)}"
PORT="${MODEL_RUNTIME_PORT:-$(runtime_value port)}"
OPENAI_BASE_URL="${MODEL_RUNTIME_BASE_URL:-$(runtime_value openai_base_url)}"
RUNTIME_DIR="${RUNTIME_DIR:-$(runtime_value runtime_dir)}"
LOG_FILE="${MODEL_RUNTIME_LOG_FILE:-$(runtime_value log_file)}"
PID_FILE="${MODEL_RUNTIME_PID_FILE:-$(runtime_value pid_file)}"
METADATA_FILE="${MODEL_RUNTIME_METADATA_FILE:-$(runtime_value metadata_file)}"

case "$RUNTIME_DIR" in
  "$ROOT"|"$ROOT"/*)
    fail "Refusing to create runtime data inside codebase: $RUNTIME_DIR"
    ;;
esac

MODEL_NAME="$(model_value "$MODEL_ID" name)"
MODEL_PATH="$(model_value "$MODEL_ID" path)"
CONTEXT="$(model_value "$MODEL_ID" context)"
GPU_LAYERS="$(model_value "$MODEL_ID" gpu_layers)"
THREADS="$(model_value "$MODEL_ID" threads)"
BATCH_SIZE="$(model_value "$MODEL_ID" batch_size)"
UBATCH_SIZE="$(model_value "$MODEL_ID" ubatch_size)"
FLASH_ATTENTION="$(model_value "$MODEL_ID" flash_attention)"
CACHE_TYPE_K="$(model_value "$MODEL_ID" cache_type_k)"
CACHE_TYPE_V="$(model_value "$MODEL_ID" cache_type_v)"

if [ -z "$MODEL_PATH" ]; then
  fail "Unknown model id: $MODEL_ID"
fi

if [ ! -x "$LLAMA_SERVER" ]; then
  fail "llama-server binary missing or not executable: $LLAMA_SERVER"
fi

if [ ! -f "$MODEL_PATH" ]; then
  fail "Model file missing: $MODEL_PATH"
fi

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"

if [ -f "$PID_FILE" ]; then
  EXISTING_PID="$(cat "$PID_FILE")"
  if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" >/dev/null 2>&1; then
    echo "llama-server already running with pid $EXISTING_PID"
    echo "Endpoint: $OPENAI_BASE_URL"
    exit 0
  fi
  rm -f "$PID_FILE" "$METADATA_FILE"
fi

command=(
  "$LLAMA_SERVER"
  --host "$HOST"
  --port "$PORT"
  --model "$MODEL_PATH"
  --ctx-size "$CONTEXT"
  --n-gpu-layers "$GPU_LAYERS"
  --threads "$THREADS"
  --batch-size "$BATCH_SIZE"
  --ubatch-size "$UBATCH_SIZE"
  --cache-type-k "$CACHE_TYPE_K"
  --cache-type-v "$CACHE_TYPE_V"
)

if [ "$FLASH_ATTENTION" = "true" ]; then
  command+=(--flash-attn on)
fi

nohup "${command[@]}" >>"$LOG_FILE" 2>&1 &
PID="$!"
echo "$PID" >"$PID_FILE"
{
  printf "MODEL_ID=%q\n" "$MODEL_ID"
  printf "MODEL_NAME=%q\n" "$MODEL_NAME"
  printf "MODEL_PATH=%q\n" "$MODEL_PATH"
  printf "OPENAI_BASE_URL=%q\n" "$OPENAI_BASE_URL"
  printf "HOST=%q\n" "$HOST"
  printf "PORT=%q\n" "$PORT"
  printf "LOG_FILE=%q\n" "$LOG_FILE"
} >"$METADATA_FILE"

echo "Started llama-server with pid $PID"
echo "Model: $MODEL_ID"
echo "Endpoint: $OPENAI_BASE_URL"
echo "Logs: $LOG_FILE"
