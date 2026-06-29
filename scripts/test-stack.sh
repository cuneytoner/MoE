#!/usr/bin/env bash
set -euo pipefail

make check-layout
make health
./scripts/test-gateway-api.sh
./scripts/test-memory-api.sh
./scripts/test-embed-worker.sh

echo "Stack tests passed"
