#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"
ROUTER_PROMPT_APPROVAL_PATH="${ROUTER_PROMPT_APPROVAL_PATH:-${RUNTIME_DIR}/reports/approvals/router-prompt-update-approval-packet.json}"
FEEDBACK_MEMORY_CANDIDATES_PATH="${FEEDBACK_MEMORY_CANDIDATES_PATH:-${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json}"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" \
  "$FEEDBACK_SUMMARY_PATH" \
  "$LEARNING_LOOP_REPORT_PATH" \
  "$IMPROVEMENT_PLAN_PATH" \
  "$ROUTER_PROMPT_APPROVAL_PATH" \
  "$FEEDBACK_MEMORY_CANDIDATES_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
input_paths = {
    "feedback_summary": sys.argv[2],
    "learning_loop_report": sys.argv[3],
    "improvement_plan": sys.argv[4],
    "router_prompt_approval": sys.argv[5],
}
output_path = pathlib.Path(sys.argv[6])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.feedback_memory_candidates import (
    build_feedback_memory_candidates,
    read_optional_json,
    write_feedback_memory_candidates,
)

inputs = {name: read_optional_json(path) for name, path in input_paths.items()}
report = build_feedback_memory_candidates(input_paths=input_paths, inputs=inputs)
written = write_feedback_memory_candidates(output_path, report)

print(f"PASS: Feedback memory candidate review written to {written}")
print(f"  candidate_status: {report['candidate_status']}")
print(f"  candidates: {len(report['candidates'])}")
print(f"  rejected_or_blocked_candidates: {len(report['rejected_or_blocked_candidates'])}")
print(f"  memory_write_supported: false")
print(f"  human_review_required: true")
for name, available in report["input_availability"].items():
    print(f"  input {name}: {'present' if available else 'missing'}")
PY
