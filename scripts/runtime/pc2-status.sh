#!/usr/bin/env bash
set -euo pipefail

section() {
  echo ""
  echo "== $1 =="
}

check_url() {
  local name="$1"
  local url="$2"
  printf '%-28s ' "$name"
  curl -fsS --max-time 2 "$url" >/dev/null 2>&1 && echo "ok $url" || echo "unreachable $url"
}

section "PC-2 status"
hostname
uptime || true
hostname -I || true

section "Docker containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

section "Worker health"
check_url "nightly-learning-worker" "http://127.0.0.1:8200/health"
check_url "research-ingestion-worker" "http://127.0.0.1:8210/health"
check_url "feedback-worker" "http://127.0.0.1:8220/health"
check_url "prompt-interpreter-worker" "http://127.0.0.1:8230/health"
