#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"

warn() {
  echo "WARN: $*" >&2
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

if command -v ping >/dev/null 2>&1; then
  if ping -c 1 -W 2 "$PC2_HOST" >/dev/null 2>&1; then
    echo "PASS: ping $PC2_HOST"
  else
    fail "PC-2 is not reachable by ping: $PC2_HOST"
  fi
else
  warn "ping command not found; skipping ping check"
fi

if ! command -v ssh >/dev/null 2>&1; then
  fail "ssh command not found"
fi

if ssh -o BatchMode=yes -o ConnectTimeout=5 "${PC2_USER}@${PC2_HOST}" "hostname && uname -a"; then
  echo "PASS: passwordless SSH to ${PC2_USER}@${PC2_HOST}"
else
  fail "PC-2 SSH check failed for ${PC2_USER}@${PC2_HOST}; ensure passwordless SSH is configured"
fi
