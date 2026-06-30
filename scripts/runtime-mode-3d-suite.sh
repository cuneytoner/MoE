#!/usr/bin/env bash
set -euo pipefail

MODE="3d_suite"
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
  echo "  grouped_capabilities: 3d_model rigging animation"
  echo "  start: media-api media-worker 3d-worker rigging-worker animation-worker prompt-interpreter-worker"
  echo "  stop: llama-server comfyui image-worker video-worker"
fi

if [ "${APPLY:-0}" = "1" ]; then
  echo "REJECTED: APPLY=1 is future-gated for $MODE in M26.1.5."
fi
