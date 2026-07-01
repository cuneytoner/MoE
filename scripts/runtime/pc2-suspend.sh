#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${APPLY:-0}" != "1" ]; then
  echo "Suspend is guarded. To suspend PC-2, run:"
  echo "  APPLY=1 scripts/runtime/pc2-suspend.sh"
  exit 0
fi

"$SCRIPT_DIR/pc2-sleep-prepare.sh"

echo ""
echo "== Suspending PC-2 =="
systemctl suspend
