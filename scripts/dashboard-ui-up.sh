#!/usr/bin/env bash
set -euo pipefail

DEPLOYED_CODEBASE_DIR="${DASHBOARD_UI_DEPLOYED_CODEBASE_DIR:-/home/cuneyt/MoE/codebase}"
SOURCE_CODEBASE_DIR="${DASHBOARD_UI_SOURCE_CODEBASE_DIR:-/home/cuneyt/DiskD/Projects/MoE/codebase}"
COMPOSE_FILE="infra/docker/docker-compose.yml"

if [ -f "$DEPLOYED_CODEBASE_DIR/$COMPOSE_FILE" ]; then
  CODEBASE_DIR="$DEPLOYED_CODEBASE_DIR"
elif [ "${ALLOW_SOURCE_DASHBOARD_UI:-0}" = "1" ] && [ -f "$SOURCE_CODEBASE_DIR/$COMPOSE_FILE" ]; then
  CODEBASE_DIR="$SOURCE_CODEBASE_DIR"
  echo "WARN: using source checkout for Dashboard UI because ALLOW_SOURCE_DASHBOARD_UI=1"
else
  echo "FAIL: deployed Dashboard UI codebase not found at $DEPLOYED_CODEBASE_DIR" >&2
  echo "Set DASHBOARD_UI_DEPLOYED_CODEBASE_DIR or deploy source to /home/cuneyt/MoE/codebase." >&2
  echo "For source-only development fallback, set ALLOW_SOURCE_DASHBOARD_UI=1 explicitly." >&2
  exit 1
fi

cd "$CODEBASE_DIR"

echo "Starting read-only Dashboard UI"
echo "  port: ${DASHBOARD_UI_PORT:-8500}"
echo "  gateway api: ${VITE_GATEWAY_API_URL:-http://127.0.0.1:8100}"

docker compose --env-file .env.example -f "$COMPOSE_FILE" --profile dashboard up -d --build dashboard-ui

echo "PASS: Dashboard UI start command completed"
