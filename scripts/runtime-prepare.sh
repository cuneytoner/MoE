#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$RUNTIME_DIR" in
  "$ROOT"|"$ROOT"/*)
    echo "Refusing to create runtime data inside codebase: $RUNTIME_DIR"
    exit 1
    ;;
esac

mkdir -p \
  "$RUNTIME_DIR/postgres" \
  "$RUNTIME_DIR/qdrant"

echo "Runtime folders ready under $RUNTIME_DIR"
