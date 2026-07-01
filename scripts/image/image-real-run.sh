#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
MEDIA_API_URL="${MEDIA_API_URL:-http://127.0.0.1:8300}"
MEDIA_WORKER_URL="${MEDIA_WORKER_URL:-http://127.0.0.1:8310}"
MEDIA_WORKER_CONTAINER="${MEDIA_WORKER_CONTAINER:-moe-media-worker}"

section() {
  echo ""
  echo "== $1 =="
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

cd "$CODEBASE_DIR"

if [ "${APPLY:-0}" != "1" ]; then
  echo "Real generation is guarded. Run:"
  echo "  APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh"
  exit 0
fi

if [ "${MEDIA_REAL_GENERATION_ENABLED:-false}" != "true" ]; then
  fail "MEDIA_REAL_GENERATION_ENABLED=true is required in the environment."
fi

section "Media API real generation gate"
media_api_health="$(curl -fsS "$MEDIA_API_URL/health")" || fail "Media API health failed"
printf '%s\n' "$media_api_health"
media_api_real="$(printf '%s\n' "$media_api_health" | jq -r '.real_generation_enabled')"
[ "$media_api_real" = "true" ] || fail "Media API real_generation_enabled is not true"

section "Media Worker real generation gate"
media_worker_health="$(curl -fsS "$MEDIA_WORKER_URL/health")" || fail "Media Worker health failed"
printf '%s\n' "$media_worker_health"
media_worker_real="$(printf '%s\n' "$media_worker_health" | jq -r '.real_generation_enabled')"
[ "$media_worker_real" = "true" ] || fail "Media Worker real_generation_enabled is not true"

section "ComfyUI host health"
make comfyui-health

section "ComfyUI bridge from Media Worker container"
if docker ps --format '{{.Names}}' | grep -qx "$MEDIA_WORKER_CONTAINER"; then
  docker exec "$MEDIA_WORKER_CONTAINER" python -c "import urllib.request; urllib.request.urlopen('http://host.docker.internal:8188/', timeout=3)"
else
  fail "Media Worker container is not running: $MEDIA_WORKER_CONTAINER"
fi

section "Flux model readiness"
REQUIRE_READY=1 make check-flux-schnell-models

section "VRAM guard"
if pgrep -af 'llama-server.*--port 8000'; then
  if [ "${ALLOW_LOW_VRAM:-0}" != "1" ]; then
    fail "llama-server appears to be running. Stop it or set ALLOW_LOW_VRAM=1 to continue anyway."
  fi
  echo "WARN: continuing with llama-server running because ALLOW_LOW_VRAM=1."
else
  echo "PASS: llama-server not detected on port 8000"
fi

section "Run real Media API bridge job"
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true make media-image-real-run

section "Latest images"
make media-latest-images

section "Media dashboard"
make media-dashboard-status
