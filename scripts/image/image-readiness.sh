#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
MEDIA_API_URL="${MEDIA_API_URL:-http://127.0.0.1:8300}"
MEDIA_WORKER_URL="${MEDIA_WORKER_URL:-http://127.0.0.1:8310}"
COMFYUI_URL="${COMFYUI_URL:-http://127.0.0.1:8188/}"
MEDIA_WORKER_CONTAINER="${MEDIA_WORKER_CONTAINER:-moe-media-worker}"

models_ready=0
comfyui_ready=0
media_api_ready=0
media_worker_ready=0
bridge_ready=0
missing_steps=()

section() {
  echo ""
  echo "== $1 =="
}

warn_step() {
  echo "WARN: $1"
  missing_steps+=("$2")
}

section "Image readiness"
if [ -d "$CODEBASE_DIR" ]; then
  echo "PASS: codebase path exists: $CODEBASE_DIR"
else
  echo "FAIL: codebase path missing: $CODEBASE_DIR"
  missing_steps+=("Check PC-1 source path: $CODEBASE_DIR")
fi
cd "$CODEBASE_DIR"

section "Flux model readiness"
if REQUIRE_READY=1 make check-flux-schnell-models; then
  models_ready=1
else
  warn_step "Flux Schnell model set is not ready" "Run make check-flux-schnell-models and complete missing model setup under /home/cuneyt/MoE_Models_Backup."
fi

section "ComfyUI host health"
if make comfyui-health; then
  comfyui_ready=1
else
  warn_step "ComfyUI host endpoint is not reachable" "For real generation, run APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh."
fi

section "ComfyUI bridge from Media Worker container"
if docker ps --format '{{.Names}}' | grep -qx "$MEDIA_WORKER_CONTAINER"; then
  if docker exec "$MEDIA_WORKER_CONTAINER" python -c "import urllib.request; urllib.request.urlopen('http://host.docker.internal:8188/', timeout=3)" >/dev/null 2>&1; then
    echo "PASS: Media Worker container can reach host ComfyUI bridge"
    bridge_ready=1
  else
    warn_step "Media Worker container cannot reach host ComfyUI bridge" "Start ComfyUI bridge mode with COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up."
  fi
else
  warn_step "Media Worker container is not running: $MEDIA_WORKER_CONTAINER" "Start media services with make pc1-startup-media-dry or APPLY=1 scripts/image/image-mode-prepare.sh."
fi

section "Media API health"
if curl -fsS "$MEDIA_API_URL/health"; then
  echo ""
  media_api_ready=1
else
  warn_step "Media API is not reachable at $MEDIA_API_URL" "Start media services with make pc1-startup-media-dry."
fi

section "Media Worker health"
if curl -fsS "$MEDIA_WORKER_URL/health"; then
  echo ""
  media_worker_ready=1
else
  warn_step "Media Worker is not reachable at $MEDIA_WORKER_URL" "Start media services with make pc1-startup-media-dry."
fi

section "Gateway media dashboard"
make media-dashboard-status || warn_step "Gateway media dashboard is not reachable" "Start Gateway with make pc1-startup-coding or make pc1-startup-media-dry."

section "VRAM status"
make comfyui-vram-status || warn_step "VRAM status check failed" "Check nvidia-smi and GPU driver status."

section "llama-server detection"
pgrep -af 'llama-server.*--port 8000' || true

section "Readiness summary"
ready_for_dry_run=false
ready_for_real_generation=false
if [ "$media_api_ready" = "1" ] && [ "$media_worker_ready" = "1" ]; then
  ready_for_dry_run=true
fi
if [ "$models_ready" = "1" ] \
  && [ "$comfyui_ready" = "1" ] \
  && [ "$bridge_ready" = "1" ] \
  && [ "$media_api_ready" = "1" ] \
  && [ "$media_worker_ready" = "1" ]; then
  ready_for_real_generation=true
fi
echo "ready_for_dry_run=$ready_for_dry_run"
echo "ready_for_real_generation=$ready_for_real_generation"
echo "missing_steps:"
if [ "${#missing_steps[@]}" -eq 0 ]; then
  echo "  none"
else
  for step in "${missing_steps[@]}"; do
    echo "  - $step"
  done
fi
