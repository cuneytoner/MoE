#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section() {
  echo ""
  echo "== $1 =="
}

section "PC-1 media dry-run startup"
"$SCRIPT_DIR/pc1-startup-media-dry.sh"

section "PC-2 prompt interpreter"
cd "$CODEBASE_DIR"
make pc2-check-connectivity || true
make pc2-sync-code || true
make pc2-prompt-interpreter-up || true
make pc2-prompt-interpreter-health || true

section "Gateway media dry-run checks"
make gateway-media-plan || true
make gateway-media-dry-run || true
make media-dashboard-status || true
