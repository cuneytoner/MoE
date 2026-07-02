#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
APPROVED_MEMORY_CANDIDATES_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
MEMORY_API_URL="${MEMORY_API_URL:-http://127.0.0.1:8101}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$FEEDBACK_MEMORY_CANDIDATES_PATH" ]; then
  echo "SKIP: Feedback memory candidates file is missing: $FEEDBACK_MEMORY_CANDIDATES_PATH"
  echo "Run make feedback-memory-candidates-local before generating a memory store plan."
  exit 0
fi

python3 - "$ROOT" \
  "$FEEDBACK_MEMORY_CANDIDATES_PATH" \
  "$MEMORY_STORE_PLAN_PATH" \
  "$APPROVED_MEMORY_CANDIDATES_PATH" \
  "$MEMORY_API_URL" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
candidates_path = pathlib.Path(sys.argv[2])
plan_path = pathlib.Path(sys.argv[3])
approval_path = pathlib.Path(sys.argv[4])
memory_api_url = sys.argv[5]
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_workflow import (
    build_memory_store_plan,
    read_optional_json,
    write_memory_store_plan,
)

candidates_report = read_optional_json(candidates_path)
approval = read_optional_json(approval_path)
plan = build_memory_store_plan(
    source_candidates_path=str(candidates_path),
    candidates_report=candidates_report,
    approval_path=str(approval_path),
    approval=approval,
    memory_api_url=memory_api_url,
)
written = write_memory_store_plan(plan_path, plan)

print(f"PASS: Human-approved memory store plan written to {written}")
print(f"  source_candidates_path: {plan['source_candidates_path']}")
print(f"  approval_file_present: {str(plan['approval_file_present']).lower()}")
print(f"  plan_status: {plan['plan_status']}")
print(f"  approved_candidates: {len(plan['approved_candidates'])}")
print(f"  blocked_candidates: {len(plan['blocked_candidates'])}")
print("  memory_write_supported: false")
print("  apply_supported: false")
print("  human_review_required: true")
PY
