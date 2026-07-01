#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$LEARNING_LOOP_REPORT_PATH" ]; then
  echo "SKIP: Learning-loop report is missing: $LEARNING_LOOP_REPORT_PATH"
  echo "Run make learning-loop-report-local before generating a human-approved improvement plan."
  exit 0
fi

python3 - "$ROOT" "$LEARNING_LOOP_REPORT_PATH" "$IMPROVEMENT_PLAN_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
report_path = pathlib.Path(sys.argv[2])
plan_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.improvement_plan import (
    build_improvement_plan,
    read_learning_loop_report,
    write_improvement_plan,
)

report = read_learning_loop_report(report_path)
plan = build_improvement_plan(report, source_report_path=str(report_path))
written = write_improvement_plan(plan_path, plan)

print(f"PASS: Human-approved improvement plan written to {written}")
print(f"  source_report_path: {plan['source_report_path']}")
print(f"  source_record_count: {plan['source_record_count']}")
print(f"  plan_status: {plan['plan_status']}")
print("  apply_supported: false")
print("  human_review_required: true")
PY
