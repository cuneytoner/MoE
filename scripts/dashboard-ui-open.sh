#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_UI_URL="${DASHBOARD_UI_URL:-http://127.0.0.1:8500}"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$DASHBOARD_UI_URL"
else
  echo "Open Dashboard UI:"
  echo "  $DASHBOARD_UI_URL"
fi
