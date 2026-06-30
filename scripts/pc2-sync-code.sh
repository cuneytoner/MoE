#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PC2_USER="${PC2_USER:-cuneyt}"
PC2_SOURCE_ROOT="${PC2_SOURCE_ROOT:-/home/cuneyt/MoE/codebase}"
PC2_TARGET="${PC2_USER}@${PC2_HOST}:${PC2_SOURCE_ROOT}/"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "FAIL: $1 is required" >&2
    exit 1
  fi
}

require_command rsync

echo "Syncing source-only codebase to PC-2"
echo "  source: ${ROOT}/"
echo "  target: ${PC2_TARGET}"
echo "  delete remote files: no"
echo "  excluded: .git, caches, venvs, node_modules, build outputs, models, runtime, data, checkpoints, custom_nodes"

rsync -av \
  --exclude ".git" \
  --exclude "__pycache__" \
  --exclude ".pytest_cache" \
  --exclude ".mypy_cache" \
  --exclude ".ruff_cache" \
  --exclude ".venv" \
  --exclude "venv" \
  --exclude "node_modules" \
  --exclude "dist" \
  --exclude "build" \
  --exclude "models" \
  --exclude "runtime" \
  --exclude "data" \
  --exclude "checkpoints" \
  --exclude "custom_nodes" \
  "${ROOT}/" \
  "${PC2_TARGET}"

echo "PASS: PC-2 source sync completed"
