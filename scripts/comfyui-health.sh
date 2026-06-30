#!/usr/bin/env bash
set -euo pipefail

COMFYUI_URL="${COMFYUI_URL:-http://127.0.0.1:8188/}"

echo "Checking ComfyUI health"
echo "  url: $COMFYUI_URL"

for attempt in $(seq 1 20); do
  echo "Attempt $attempt/20"
  if curl -fsS "$COMFYUI_URL" >/dev/null 2>&1; then
    echo "PASS: ComfyUI responded at $COMFYUI_URL"
    exit 0
  fi
  sleep 1
done

echo "FAIL: ComfyUI did not respond after 20 seconds."
exit 1
