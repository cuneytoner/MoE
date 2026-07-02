#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_PLAN_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-plan.json"
MEMORY_API_URL="${MEMORY_API_URL:-http://127.0.0.1:8101}"
APPLY="${APPLY:-0}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$MEMORY_STORE_PLAN_PATH" ]; then
  echo "SKIP: Memory store plan is missing: $MEMORY_STORE_PLAN_PATH"
  echo "Run make memory-store-plan-local before storing approved memory candidates."
  exit 0
fi

payload_dir="$(mktemp -d /tmp/moe-memory-store-payloads.XXXXXX)"
trap 'rm -rf "$payload_dir"' EXIT

python3 - "$ROOT" "$MEMORY_STORE_PLAN_PATH" "$payload_dir" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plan_path = pathlib.Path(sys.argv[2])
payload_dir = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_workflow import memory_add_payload

plan = json.loads(plan_path.read_text(encoding="utf-8"))
approved = plan.get("approved_candidates")
if not isinstance(approved, list):
    approved = []

print(f"APPROVED_COUNT={len(approved)}")
for index, candidate in enumerate(approved, start=1):
    if not isinstance(candidate, dict):
        continue
    payload = candidate.get("store_payload")
    if not isinstance(payload, dict):
        payload = memory_add_payload(candidate)
    payload_path = payload_dir / f"memory-payload-{index:03d}.json"
    payload_path.write_text(json.dumps(payload, sort_keys=True) + "\n", encoding="utf-8")
    print(f"PAYLOAD\t{candidate.get('id', f'candidate-{index:03d}')}\t{payload_path}")
PY

approved_count="$(
  python3 - "$MEMORY_STORE_PLAN_PATH" <<'PY'
import json
import pathlib
import sys

plan = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
approved = plan.get("approved_candidates")
print(len(approved) if isinstance(approved, list) else 0)
PY
)"

if [ "$approved_count" -eq 0 ]; then
  echo "SKIP: No approved memory candidates are present in $MEMORY_STORE_PLAN_PATH"
  echo "Create approved-memory-candidates.json, rerun make memory-store-plan-local, then inspect dry-run output."
  exit 0
fi

if [ "$APPLY" != "1" ]; then
  echo "DRY-RUN: Memory API writes are disabled. Set APPLY=1 to store approved candidates."
  for payload in "$payload_dir"/memory-payload-*.json; do
    [ -f "$payload" ] || continue
    echo "DRY-RUN: curl -sS '${MEMORY_API_URL%/}/memory/add' -H 'Content-Type: application/json' -d @${payload}"
  done
  exit 0
fi

echo "APPLY=1: storing approved memory candidates through ${MEMORY_API_URL%/}/memory/add"
for payload in "$payload_dir"/memory-payload-*.json; do
  [ -f "$payload" ] || continue
  response="$(
    curl -sS -f \
      -H "Content-Type: application/json" \
      -X POST \
      -d @"$payload" \
      "${MEMORY_API_URL%/}/memory/add"
  )"
  echo "PASS: Memory API stored approved candidate from $payload"
  echo "$response"
done
