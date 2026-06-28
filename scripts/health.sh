#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-moe}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
QDRANT_PORT="${QDRANT_PORT:-6333}"

check_port() {
  local host="$1"
  local port="$2"

  timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" >/dev/null 2>&1
}

check_http() {
  local url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$url" >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url" >/dev/null 2>&1
  else
    echo "HTTP health check unavailable: curl or wget is required"
    return 1
  fi
}

container_running() {
  local name="$1"

  docker ps --format '{{.Names}}' | grep -qx "$name"
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker unavailable: docker command not found"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker unavailable: daemon is not reachable"
  exit 1
fi

echo "Docker OK"

if container_running "$PROJECT_NAME-postgres"; then
  if check_port 127.0.0.1 "$POSTGRES_PORT"; then
    echo "PostgreSQL port OK: $POSTGRES_PORT"
  else
    echo "PostgreSQL port unreachable: $POSTGRES_PORT"
    exit 1
  fi
else
  echo "PostgreSQL not running; skipping port check"
fi

if container_running "$PROJECT_NAME-qdrant"; then
  if check_http "http://127.0.0.1:$QDRANT_PORT/readyz"; then
    echo "Qdrant HTTP health OK: $QDRANT_PORT"
  else
    echo "Qdrant HTTP health unreachable: $QDRANT_PORT"
    exit 1
  fi
else
  echo "Qdrant not running; skipping HTTP health check"
fi
