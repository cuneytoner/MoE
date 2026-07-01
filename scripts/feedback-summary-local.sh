#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_JSONL_PATH="${FEEDBACK_JSONL_PATH:-${RUNTIME_DIR}/feedback/gateway-feedback.jsonl}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" "$FEEDBACK_JSONL_PATH" "$FEEDBACK_SUMMARY_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
source_path = pathlib.Path(sys.argv[2])
summary_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.gateway_summary import summarize_feedback_file, write_summary

summary = summarize_feedback_file(source_path)
written = write_summary(summary_path, summary)
print(f"PASS: Feedback summary written to {written}")
print(f"  source_path: {summary['source_path']}")
print(f"  record_count: {summary['record_count']}")
print(f"  malformed_count: {summary['malformed_count']}")
PY
