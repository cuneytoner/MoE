#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
HELPER_REPORT_PATH="${RUNTIME_DIR}/reports/memory-store/memory-candidate-approval-helper-report.json"
FEEDBACK_MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" "$HELPER_REPORT_PATH" "$FEEDBACK_MEMORY_CANDIDATES_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
helper_report_path = pathlib.Path(sys.argv[2])
candidates_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_candidate_approval_helper import (
    list_rows_from_candidates,
    list_rows_from_report,
    read_optional_json,
)

rows = []
source = None
report = read_optional_json(helper_report_path)
if report:
    rows = list_rows_from_report(report)
    source = helper_report_path
else:
    candidates = read_optional_json(candidates_path)
    if candidates:
        rows = list_rows_from_candidates(candidates)
        source = candidates_path

if not rows:
    print("SKIP: No memory candidates are available to list.")
    print(f"Checked helper report: {helper_report_path}")
    print(f"Checked candidates file: {candidates_path}")
    raise SystemExit(0)

print(f"Memory candidate review list from {source}")
print("id | category | risk | status | duplicate? | title")
print("--- | --- | --- | --- | --- | ---")
for row in rows:
    print(
        f"{row['id']} | {row['category']} | {row['risk']} | "
        f"{row['status']} | {row['duplicate']} | {row['title']}"
    )
PY
