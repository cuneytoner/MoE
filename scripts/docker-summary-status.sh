#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT_PATH="${DOCKER_SUMMARY_SNAPSHOT_PATH:-${HOME}/MoE/runtime/status/docker-summary.json}"

if [ ! -f "$SNAPSHOT_PATH" ]; then
  echo "FAIL: Docker summary snapshot not found: $SNAPSHOT_PATH" >&2
  echo "Run: make docker-summary-snapshot" >&2
  exit 1
fi

jq '.' "$SNAPSHOT_PATH"
