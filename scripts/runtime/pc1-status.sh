#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"

section() {
  echo ""
  echo "== $1 =="
}

check_url() {
  local name="$1"
  local url="$2"
  printf '%-18s ' "$name"
  curl -fsS --max-time 2 "$url" >/dev/null 2>&1 && echo "ok $url" || echo "unreachable $url"
}

section "PC-1 status"
hostname
uptime || true

section "Docker containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

section "Endpoint health"
check_url "gateway" "http://127.0.0.1:8100/gateway/health"
check_url "memory" "http://127.0.0.1:8101/health"
check_url "embed" "http://127.0.0.1:8102/health"
check_url "media-api" "http://127.0.0.1:8300/health"
check_url "media-worker" "http://127.0.0.1:8310/health"
check_url "comfyui" "http://127.0.0.1:8188/"
check_url "llama-server" "http://127.0.0.1:8000/v1/models"

section "GPU status"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "nvidia-smi not available"
fi

section "Latest media images"
cd "$CODEBASE_DIR"
make media-latest-images || true
