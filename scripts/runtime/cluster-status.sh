#!/usr/bin/env bash
set -euo pipefail

PC2_USER="cuneyt"
PC2_HOST="192.168.50.2"
PC2_CODEBASE="/home/cuneyt/MoE/codebase"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section() {
  echo ""
  echo "== $1 =="
}

section "PC-1 status"
"$SCRIPT_DIR/pc1-status.sh"

section "PC-2 status"
if ssh "$PC2_USER@$PC2_HOST" "test -x '$PC2_CODEBASE/scripts/runtime/pc2-status.sh'"; then
  ssh "$PC2_USER@$PC2_HOST" "'$PC2_CODEBASE/scripts/runtime/pc2-status.sh'"
else
  echo "WARN: remote PC-2 status script missing; falling back to docker ps"
  ssh "$PC2_USER@$PC2_HOST" 'docker ps' || true
fi
