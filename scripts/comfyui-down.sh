#!/usr/bin/env bash
set -euo pipefail

COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
COMFYUI_PID_FILE="$COMFYUI_RUNTIME_DIR/comfyui.pid"

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must be /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

if [ ! -f "$COMFYUI_PID_FILE" ]; then
  echo "PASS: ComfyUI PID file is absent; nothing to stop."
  exit 0
fi

pid="$(cat "$COMFYUI_PID_FILE")"
if [ -z "$pid" ]; then
  echo "WARN: PID file is empty: $COMFYUI_PID_FILE"
  rm -f "$COMFYUI_PID_FILE"
  exit 0
fi

if ! kill -0 "$pid" >/dev/null 2>&1; then
  echo "WARN: PID $pid is not running; removing stale PID file."
  rm -f "$COMFYUI_PID_FILE"
  exit 0
fi

echo "Stopping ComfyUI PID $pid"
kill "$pid"

for attempt in $(seq 1 20); do
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    rm -f "$COMFYUI_PID_FILE"
    echo "PASS: ComfyUI stopped."
    exit 0
  fi
  echo "Waiting for ComfyUI to stop: attempt $attempt/20"
  sleep 1
done

echo "FAIL: ComfyUI PID $pid did not stop after 20 seconds."
exit 1
