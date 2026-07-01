#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$FEEDBACK_SUMMARY_PATH" ]; then
  echo "SKIP: Feedback summary file is missing: $FEEDBACK_SUMMARY_PATH"
  echo "Run make feedback-summary-local first, or sync/generate the summary before creating a learning loop report."
  exit 0
fi

python3 - "$ROOT" "$FEEDBACK_SUMMARY_PATH" "$LEARNING_LOOP_REPORT_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
summary_path = pathlib.Path(sys.argv[2])
report_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.learning_loop import (
    build_learning_loop_report,
    read_summary,
    write_learning_loop_report,
)

summary = read_summary(summary_path)
report = build_learning_loop_report(summary, source_summary_path=str(summary_path))
written = write_learning_loop_report(report_path, report)

print(f"PASS: Learning loop report written to {written}")
print(f"  source_summary_path: {report['source_summary_path']}")
print(f"  source_record_count: {report['source_record_count']}")
print("  apply_supported: false")
print("  human_review_required: true")
PY
