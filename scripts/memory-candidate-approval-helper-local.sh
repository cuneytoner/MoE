#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
MEMORY_STORE_AUDIT_PATH="${MEMORY_STORE_DIR}/memory-store-audit.json"
APPROVED_MEMORY_CANDIDATES_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
EXAMPLE_APPROVAL_FILE_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.example.json"
HELPER_REPORT_PATH="${MEMORY_STORE_DIR}/memory-candidate-approval-helper-report.json"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" \
  "$FEEDBACK_MEMORY_CANDIDATES_PATH" \
  "$MEMORY_STORE_PLAN_PATH" \
  "$MEMORY_STORE_AUDIT_PATH" \
  "$APPROVED_MEMORY_CANDIDATES_PATH" \
  "$EXAMPLE_APPROVAL_FILE_PATH" \
  "$HELPER_REPORT_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
candidates_path = pathlib.Path(sys.argv[2])
plan_path = pathlib.Path(sys.argv[3])
audit_path = pathlib.Path(sys.argv[4])
approval_path = pathlib.Path(sys.argv[5])
example_path = pathlib.Path(sys.argv[6])
report_path = pathlib.Path(sys.argv[7])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_candidate_approval_helper import (
    build_approval_helper_report,
    build_example_approval_file,
    read_optional_json,
    write_json,
)

input_paths = {
    "feedback_memory_candidates": str(candidates_path),
    "memory_store_plan": str(plan_path),
    "memory_store_audit": str(audit_path),
}
inputs = {
    "feedback_memory_candidates": read_optional_json(candidates_path),
    "memory_store_plan": read_optional_json(plan_path),
    "memory_store_audit": read_optional_json(audit_path),
}
report = build_approval_helper_report(
    input_paths=input_paths,
    inputs=inputs,
    approval_file_path=str(approval_path),
    example_approval_file_path=str(example_path),
)
written_report = write_json(report_path, report)
written_example = write_json(example_path, build_example_approval_file())

print(f"PASS: Memory candidate approval helper report written to {written_report}")
print(f"PASS: Example approval file written to {written_example}")
print(f"  helper_status: {report['helper_status']}")
print(f"  total_candidates: {report['candidate_summary']['total_candidates']}")
print(f"  approved_count: {report['candidate_summary']['approved_count']}")
print(f"  blocked_count: {report['candidate_summary']['blocked_count']}")
print(f"  duplicate_group_count: {report['candidate_summary']['duplicate_group_count']}")
print("  auto_approval_supported: false")
print("  memory_write_supported: false")
print("  human_review_required: true")
print(f"NOTE: real approval file was not created: {approval_path}")
PY
