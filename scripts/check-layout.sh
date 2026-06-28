#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  "apps/gateway-api"
  "apps/memory-api"
  "apps/memory-api/app/__init__.py"
  "apps/memory-api/app/main.py"
  "apps/memory-api/app/config.py"
  "apps/memory-api/app/clients/__init__.py"
  "apps/memory-api/app/clients/postgres.py"
  "apps/memory-api/app/clients/qdrant.py"
  "apps/memory-api/app/models/__init__.py"
  "apps/memory-api/app/models/memory.py"
  "apps/memory-api/requirements.txt"
  "apps/memory-api/Dockerfile"
  "apps/memory-api/README.md"
  "apps/embed-worker"
  "apps/dashboard"
  "packages/shared"
  "packages/schemas"
  "packages/clients"
  "infra/docker"
  "infra/docker/docker-compose.yml"
  "infra/postgres"
  "infra/postgres/init/01-init.sql"
  "infra/qdrant"
  "infra/qdrant/README.md"
  "infra/scripts"
  "deploy/pc1"
  "deploy/pc2"
  "docs"
  "scripts"
  "README.md"
  ".gitignore"
  ".env.example"
  "docs/architecture.md"
  "docs/milestones.md"
  "docs/runtime-rules.md"
  "docs/deployment.md"
  "docs/codex-prompts.md"
  "docs/docker-foundation.md"
  "docs/memory-api.md"
  "scripts/runtime-prepare.sh"
  "scripts/health.sh"
)

for path in "${required_paths[@]}"; do
  if [ ! -e "$ROOT/$path" ]; then
    echo "Missing: $path"
    exit 1
  fi
done

for forbidden in \
  "venv" \
  ".venv" \
  "__pycache__" \
  "node_modules" \
  "logs" \
  "data" \
  "runtime" \
  "models" \
  "checkpoints" \
  "moe_memory.db"
do
  if [ -e "$ROOT/$forbidden" ]; then
    echo "Forbidden runtime artifact in codebase: $forbidden"
    exit 1
  fi
done

while IFS= read -r forbidden_path; do
  if [ -n "$forbidden_path" ]; then
    echo "Forbidden generated artifact in codebase: ${forbidden_path#$ROOT/}"
    exit 1
  fi
done < <(find "$ROOT" \
  \( -path "$ROOT/.git" -o -path "$ROOT/.git/*" \) -prune \
  -o \( -name "__pycache__" -o -name "*.pyc" \) -print)

echo "Layout OK"
