#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"
SCRIPT="$ROOT/scripts/learning-loop-report-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "learning loop report script exists and is executable"

if [ ! -f "$FEEDBACK_SUMMARY_PATH" ]; then
  mkdir -p "$(dirname "$FEEDBACK_SUMMARY_PATH")"
  cat > "$FEEDBACK_SUMMARY_PATH" <<'JSON'
{
  "generated_at": "2026-01-01T00:00:00Z",
  "latest_created_at": "2026-01-01T00:00:00Z",
  "malformed_count": 0,
  "model_counts": {
    "gateway-auto": 3
  },
  "rating_counts": {
    "accepted": 1,
    "neutral": 0,
    "not_useful": 0,
    "rejected": 0,
    "useful": 2
  },
  "record_count": 3,
  "router_intent_counts": {
    "architecture": 3
  },
  "source_counts": {
    "manual": 3
  },
  "source_path": "/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl",
  "top_tags": [
    {
      "count": 3,
      "tag": "gateway"
    },
    {
      "count": 1,
      "tag": "tests"
    }
  ]
}
JSON
  pass "created minimal runtime feedback summary"
else
  pass "using existing runtime feedback summary"
fi

"$SCRIPT"

[ -f "$LEARNING_LOOP_REPORT_PATH" ] || fail "missing learning loop report: $LEARNING_LOOP_REPORT_PATH"
pass "learning loop report exists under runtime"

python3 - "$ROOT" "$LEARNING_LOOP_REPORT_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
report_path = pathlib.Path(sys.argv[2]).resolve()
report = json.loads(report_path.read_text(encoding="utf-8"))

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in report_path.parents:
    fail(f"report was written inside the repository: {report_path}")
if report.get("apply_supported") is not False:
    fail(f"apply_supported must be false: {report}")
if report.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {report}")
for forbidden in ("prompt", "response", "records", "feedback_records"):
    if forbidden in report:
        fail(f"forbidden raw field present: {forbidden}")
serialized = json.dumps(report, sort_keys=True).lower()
for forbidden_text in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text"):
    if forbidden_text in serialized:
        fail(f"forbidden raw text marker present: {forbidden_text}")
print("PASS: learning loop report contract is safe")
PY

if find "$ROOT" -name "learning-loop-report.json" -print -quit | grep -q .; then
  fail "learning-loop-report.json was written inside the repository"
fi
pass "no learning loop report output was written into the repo"

echo "Learning loop report tests passed"
