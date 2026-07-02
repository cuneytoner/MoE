#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_PLAN_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-plan.json"
FEEDBACK_MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_AUDIT_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-audit.json"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$MEMORY_STORE_PLAN_PATH" ]; then
  echo "SKIP: Memory store plan is missing: $MEMORY_STORE_PLAN_PATH"
  echo "Run make memory-store-plan-local before generating a memory store audit."
  exit 0
fi

python3 - "$ROOT" \
  "$MEMORY_STORE_PLAN_PATH" \
  "$FEEDBACK_MEMORY_CANDIDATES_PATH" \
  "$MEMORY_STORE_AUDIT_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plan_path = pathlib.Path(sys.argv[2])
candidates_path = pathlib.Path(sys.argv[3])
audit_path = pathlib.Path(sys.argv[4])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_audit import (
    build_memory_store_audit,
    read_optional_json,
    write_memory_store_audit,
)

plan = read_optional_json(plan_path)
candidates_report = read_optional_json(candidates_path)
audit = build_memory_store_audit(
    source_plan_path=str(plan_path),
    source_candidates_path=str(candidates_path),
    plan=plan,
    candidates_report=candidates_report,
)
written = write_memory_store_audit(audit_path, audit)

print(f"PASS: Memory store audit written to {written}")
print(f"  audit_status: {audit['audit_status']}")
print(f"  approved_count: {audit['counts']['approved_count']}")
print(f"  blocked_count: {audit['counts']['blocked_count']}")
print(f"  duplicate_group_count: {audit['counts']['duplicate_group_count']}")
print(f"  duplicate_candidate_count: {audit['counts']['duplicate_candidate_count']}")
print("  memory_write_supported: false")
print("  apply_supported: false")
print("  human_review_required: true")
PY
