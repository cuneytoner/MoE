#!/usr/bin/env bash
set -euo pipefail

RUNTIME_ROOT="${RUNTIME_ROOT:-/home/cuneyt/MoE/runtime}"

echo "MoE runtime status (read-only)"
echo "  runtime root: $RUNTIME_ROOT"
echo ""

check_http() {
  local name="$1"
  local url="$2"

  if curl -fsS --max-time 1 "$url" >/dev/null 2>&1; then
    echo "PASS: $name HTTP reachable ($url)"
  else
    echo "WARN: $name HTTP not reachable ($url)"
  fi
}

check_pid_file() {
  local name="$1"
  local path="$2"

  if [ -f "$path" ]; then
    echo "INFO: $name PID file present: $path pid=$(cat "$path")"
  else
    echo "INFO: $name PID file missing: $path"
  fi
}

check_http "llama-server" "http://127.0.0.1:8000/v1/models"
check_http "gateway-api" "http://127.0.0.1:8100/gateway/health"
check_http "memory-api" "http://127.0.0.1:8101/health"
check_http "embed-worker" "http://127.0.0.1:8102/health"
check_http "qdrant" "http://127.0.0.1:6333/"
check_http "comfyui" "http://127.0.0.1:8188/"
check_http "nightly-learning-worker" "http://127.0.0.1:8200/health"
check_http "research-ingestion-worker" "http://127.0.0.1:8210/health"
check_http "feedback-worker" "http://127.0.0.1:8220/health"
check_http "prompt-interpreter-worker" "http://127.0.0.1:8230/health"
check_http "media-api" "http://127.0.0.1:8300/health"
check_http "media-worker" "http://127.0.0.1:8310/health"

echo ""
check_pid_file "llama-server" "$RUNTIME_ROOT/model-runtime.pid"
check_pid_file "comfyui" "$RUNTIME_ROOT/media-engines/comfyui/comfyui.pid"

echo ""
if command -v docker >/dev/null 2>&1; then
  echo "Known Docker containers (read-only):"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -E 'moe|gateway|memory|embed|postgres|qdrant|media|worker' || true
else
  echo "INFO: docker command not available."
fi

echo ""
echo "INFO: runtime-status is read-only and does not start, stop, or modify services."
