#!/usr/bin/env bash
set -euo pipefail

PC2_USER="cuneyt"
PC2_HOST="192.168.50.2"
PC2_CODEBASE="/home/cuneyt/MoE/codebase"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${APPLY:-0}" != "1" ]; then
  echo "Cluster suspend is guarded. To suspend PC-2 then PC-1, run:"
  echo "  APPLY=1 scripts/runtime/cluster-suspend.sh"
  exit 0
fi

"$SCRIPT_DIR/cluster-sleep-prepare.sh"

echo ""
echo "== Suspending PC-2 first =="
if ssh "$PC2_USER@$PC2_HOST" "test -x '$PC2_CODEBASE/scripts/runtime/pc2-suspend.sh'"; then
  ssh "$PC2_USER@$PC2_HOST" "APPLY=1 '$PC2_CODEBASE/scripts/runtime/pc2-suspend.sh'"
else
  echo "WARN: remote PC-2 suspend script missing; falling back to sudo systemctl suspend"
  ssh "$PC2_USER@$PC2_HOST" 'sudo systemctl suspend'
fi

sleep 3

echo ""
echo "== Suspending PC-1 =="
systemctl suspend
