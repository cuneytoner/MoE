#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section() {
  echo ""
  echo "== $1 =="
}

section "PC-1 coding startup"
"$SCRIPT_DIR/pc1-startup-coding.sh"

section "PC-2 worker startup"
cd "$CODEBASE_DIR"
make pc2-check-connectivity || true
make pc2-sync-code || true
make pc2-nightly-up || true
make pc2-research-up || true
make pc2-feedback-up || true
make pc2-prompt-interpreter-up || true

section "Cluster health"
make pc2-prompt-interpreter-health || true
make media-dashboard-status || true
