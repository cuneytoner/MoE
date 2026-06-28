#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  "apps/gateway-api"
  "apps/memory-api"
  "apps/embed-worker"
  "apps/dashboard"
  "packages/shared"
  "packages/schemas"
  "packages/clients"
  "infra/docker"
  "infra/postgres"
  "infra/qdrant"
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

echo "Layout OK"
