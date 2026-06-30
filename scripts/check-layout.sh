#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_paths=(
  "apps/gateway-api"
  "apps/gateway-api/app/__init__.py"
  "apps/gateway-api/app/main.py"
  "apps/gateway-api/app/config.py"
  "apps/gateway-api/app/clients/__init__.py"
  "apps/gateway-api/app/clients/memory_api.py"
  "apps/gateway-api/app/clients/embed_worker.py"
  "apps/gateway-api/app/clients/model_runtime.py"
  "apps/gateway-api/app/models/__init__.py"
  "apps/gateway-api/app/models/gateway.py"
  "apps/gateway-api/app/services/__init__.py"
  "apps/gateway-api/app/services/model_mapping.py"
  "apps/gateway-api/app/services/router.py"
  "apps/gateway-api/requirements.txt"
  "apps/gateway-api/Dockerfile"
  "apps/memory-api"
  "apps/memory-api/app/__init__.py"
  "apps/memory-api/app/main.py"
  "apps/memory-api/app/config.py"
  "apps/memory-api/app/clients/__init__.py"
  "apps/memory-api/app/clients/embed_worker.py"
  "apps/memory-api/app/clients/postgres.py"
  "apps/memory-api/app/clients/qdrant.py"
  "apps/memory-api/app/models/__init__.py"
  "apps/memory-api/app/models/memory.py"
  "apps/memory-api/app/services/__init__.py"
  "apps/memory-api/app/services/memory_store.py"
  "apps/memory-api/requirements.txt"
  "apps/memory-api/Dockerfile"
  "apps/memory-api/README.md"
  "apps/embed-worker"
  "apps/embed-worker/app/__init__.py"
  "apps/embed-worker/app/main.py"
  "apps/embed-worker/app/config.py"
  "apps/embed-worker/app/models/__init__.py"
  "apps/embed-worker/app/models/embed.py"
  "apps/embed-worker/app/services/__init__.py"
  "apps/embed-worker/app/services/bge_m3_embedder.py"
  "apps/embed-worker/app/services/embedder_factory.py"
  "apps/embed-worker/app/services/fake_embedder.py"
  "apps/embed-worker/requirements.txt"
  "apps/embed-worker/Dockerfile"
  "apps/embed-worker/README.md"
  "apps/dashboard"
  "configs"
  "configs/environments"
  "configs/environments/README.md"
  "configs/environments/pc1-main.example.yaml"
  "configs/environments/pc1.local.example.yaml"
  "configs/environments/pc2-worker.example.yaml"
  "configs/environments/pc2.local.example.yaml"
  "configs/environments/single-machine.example.yaml"
  "configs/environments/new-machine.template.yaml"
  "configs/continue"
  "configs/continue/config-gateway.yaml.example"
  "configs/continue/config-runtime-direct.yaml.example"
  "configs/model-routing.yaml"
  "configs/models.yaml"
  "configs/runtime.yaml"
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
  "deploy/pc2/README.md"
  "deploy/pc2/docker-compose.worker.example.yml"
  "deploy/pc2/.env.example"
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
  "docs/embed-worker.md"
  "docs/model-runtime.md"
  "docs/backup-restore.md"
  "docs/environment-profiles.md"
  "docs/gateway-api.md"
  "docs/continue-dev.md"
  "docs/pc2-worker-node.md"
  "scripts/runtime-prepare.sh"
  "scripts/health.sh"
  "scripts/check-pc2-connectivity.sh"
  "scripts/check-pc2-layout.sh"
  "scripts/check-python-syntax.sh"
  "scripts/check-models.sh"
  "scripts/model-runtime-start.sh"
  "scripts/model-runtime-stop.sh"
  "scripts/model-runtime-status.sh"
  "scripts/model-runtime-health.sh"
  "scripts/model-runtime-switch.sh"
  "scripts/test-gateway-api.sh"
  "scripts/test-continue-gateway.sh"
  "scripts/test-memory-api.sh"
  "scripts/test-bge-m3-runtime.sh"
  "scripts/test-embed-worker.sh"
  "scripts/test-stack.sh"
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
