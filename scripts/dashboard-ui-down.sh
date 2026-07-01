#!/usr/bin/env bash
set -euo pipefail

CODEBASE_DIR="/home/cuneyt/DiskD/Projects/MoE/codebase"
COMPOSE_FILE="infra/docker/docker-compose.yml"

cd "$CODEBASE_DIR"

echo "Stopping Dashboard UI only"
docker compose --env-file .env.example -f "$COMPOSE_FILE" --profile dashboard stop dashboard-ui
echo "PASS: Dashboard UI stop command completed"
