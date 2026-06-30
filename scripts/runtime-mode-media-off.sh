#!/usr/bin/env bash
set -euo pipefail

MODE="media_off"
CONTROL_API_URL="${CONTROL_API_URL:-http://127.0.0.1:8400}"

echo "Runtime mode plan: $MODE"
echo "  apply: ${APPLY:-0}"

if curl -fsS --max-time 1 "$CONTROL_API_URL/health" >/dev/null 2>&1; then
  curl -fsS -H "Content-Type: application/json" -X POST \
    -d "{\"mode\":\"$MODE\"}" \
    "$CONTROL_API_URL/control/mode/plan"
  echo ""
else
  echo "Control API is not reachable; static fallback plan:"
  echo "  start: none"
  echo "  stop: comfyui media-api media-worker image-worker video-worker 3d-worker rigging-worker animation-worker prompt-interpreter-worker"
fi

if [ "${APPLY:-0}" = "1" ]; then
  echo "REJECTED: APPLY=1 is future-gated for $MODE in M26.1.5."
fi
