#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"

section() {
  echo ""
  echo "== $1 =="
}

cd "$CODEBASE_DIR"

section "Gateway media plan"
make gateway-media-plan

section "Gateway media dry-run job"
make gateway-media-dry-run

section "Media dashboard"
make media-dashboard-status

section "Done"
echo "Dry-run complete. ComfyUI was not started and real generation was not enabled."
