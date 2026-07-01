#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${APPLY:-0}" != "1" ]; then
  echo "Suspend is guarded. To suspend PC-1, run:"
  echo "  APPLY=1 scripts/runtime/pc1-suspend.sh"
  exit 0
fi

"$SCRIPT_DIR/pc1-sleep-prepare.sh"

echo ""
echo "== Suspending PC-1 =="
systemctl suspend
