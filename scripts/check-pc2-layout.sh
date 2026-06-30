#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_RUNTIME_ROOT="${PC2_RUNTIME_ROOT:-/home/cuneyt/MoE}"
PC2_RUNTIME_DIR="${PC2_RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

if ! command -v ssh >/dev/null 2>&1; then
  fail "ssh command not found"
fi

remote_check() {
  local description="$1"
  local command="$2"

  if ssh -o BatchMode=yes -o ConnectTimeout=5 "${PC2_USER}@${PC2_HOST}" "$command"; then
    echo "PASS: $description"
  else
    fail "$description"
  fi
}

remote_check "$PC2_RUNTIME_ROOT exists" "test -d '$PC2_RUNTIME_ROOT'"
remote_check "$PC2_RUNTIME_DIR exists" "test -d '$PC2_RUNTIME_DIR'"
remote_check "docker command exists on PC-2" "command -v docker >/dev/null 2>&1"
remote_check "docker compose version works on PC-2" "docker compose version >/dev/null 2>&1"
