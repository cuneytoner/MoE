#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
COMPOSE_FILE="infra/docker/docker-compose.yml"

cd "$CODEBASE_DIR"

echo "Starting read-only Dashboard UI"
echo "  port: ${DASHBOARD_UI_PORT:-8500}"
echo "  gateway api: ${VITE_GATEWAY_API_URL:-http://127.0.0.1:8100}"

docker compose --env-file .env.example -f "$COMPOSE_FILE" --profile dashboard up -d --build dashboard-ui

echo "PASS: Dashboard UI start command completed"
