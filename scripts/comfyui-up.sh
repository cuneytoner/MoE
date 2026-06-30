#!/usr/bin/env bash
set -euo pipefail

COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/media-engines/comfyui}"
COMFYUI_HOST="${COMFYUI_HOST:-127.0.0.1}"
COMFYUI_PORT="${COMFYUI_PORT:-8188}"
COMFYUI_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI"
COMFYUI_VENV="$COMFYUI_RUNTIME_DIR/venv"
COMFYUI_LOG_DIR="$COMFYUI_RUNTIME_DIR/logs"
COMFYUI_PID_FILE="$COMFYUI_RUNTIME_DIR/comfyui.pid"
COMFYUI_LOG_FILE="$COMFYUI_LOG_DIR/comfyui.log"

case "$COMFYUI_RUNTIME_DIR" in
  /home/cuneyt/MoE/runtime/media-engines/comfyui)
    ;;
  *)
    echo "FAIL: COMFYUI_RUNTIME_DIR must be /home/cuneyt/MoE/runtime/media-engines/comfyui"
    exit 1
    ;;
esac

if [ "$COMFYUI_HOST" != "127.0.0.1" ]; then
  echo "FAIL: COMFYUI_HOST defaults to 127.0.0.1 and must not expose to LAN in this milestone."
  exit 1
fi

if [ -f "$COMFYUI_PID_FILE" ]; then
  old_pid="$(cat "$COMFYUI_PID_FILE")"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" >/dev/null 2>&1; then
    echo "PASS: ComfyUI already running with PID $old_pid"
    exit 0
  fi
  echo "WARN: stale PID file found: $COMFYUI_PID_FILE"
fi

if [ ! -x "$COMFYUI_VENV/bin/python" ]; then
  echo "FAIL: runtime python missing: $COMFYUI_VENV/bin/python"
  echo "Run make install-comfyui-runtime first."
  exit 1
fi

if [ ! -f "$COMFYUI_DIR/main.py" ]; then
  echo "FAIL: ComfyUI main.py missing: $COMFYUI_DIR/main.py"
  echo "Run make install-comfyui-runtime first."
  exit 1
fi

mkdir -p "$COMFYUI_LOG_DIR"

echo "Starting ComfyUI on http://$COMFYUI_HOST:$COMFYUI_PORT"
echo "  log: $COMFYUI_LOG_FILE"
echo "  pid: $COMFYUI_PID_FILE"

cd "$COMFYUI_DIR"
nohup "$COMFYUI_VENV/bin/python" main.py --listen "$COMFYUI_HOST" --port "$COMFYUI_PORT" >"$COMFYUI_LOG_FILE" 2>&1 &
pid="$!"
echo "$pid" >"$COMFYUI_PID_FILE"
echo "PASS: ComfyUI started with PID $pid"
