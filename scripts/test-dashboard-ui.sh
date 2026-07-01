#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_UI_URL="${DASHBOARD_UI_URL:-http://127.0.0.1:8500}"

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

required_paths=(
  "apps/dashboard-ui/package.json"
  "apps/dashboard-ui/index.html"
  "apps/dashboard-ui/src/main.tsx"
  "apps/dashboard-ui/src/App.tsx"
  "apps/dashboard-ui/src/vite-env.d.ts"
  "apps/dashboard-ui/src/api.ts"
  "apps/dashboard-ui/src/types.ts"
  "apps/dashboard-ui/src/components/StatusCard.tsx"
  "apps/dashboard-ui/src/components/GatesPanel.tsx"
  "apps/dashboard-ui/src/components/ServicesPanel.tsx"
  "apps/dashboard-ui/src/components/LatestImagesPanel.tsx"
  "apps/dashboard-ui/src/components/SafeCommandsPanel.tsx"
  "apps/dashboard-ui/src/components/ModeHintsPanel.tsx"
  "apps/dashboard-ui/src/styles.css"
  "apps/dashboard-ui/Dockerfile"
)

for path in "${required_paths[@]}"; do
  if [ ! -f "$path" ]; then
    fail "missing Dashboard UI file: $path"
  fi
done
pass "Dashboard UI source files exist"

if curl -fsS --max-time 2 "$DASHBOARD_UI_URL" >/dev/null 2>&1; then
  pass "Dashboard UI live endpoint reachable"
else
  echo "WARN: Dashboard UI is not running at $DASHBOARD_UI_URL; skipping live curl"
fi
