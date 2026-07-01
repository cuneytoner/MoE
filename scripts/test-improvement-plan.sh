#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"
SCRIPT="$ROOT/scripts/improvement-plan-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "improvement plan script exists and is executable"

if [ ! -f "$LEARNING_LOOP_REPORT_PATH" ]; then
  mkdir -p "$(dirname "$LEARNING_LOOP_REPORT_PATH")"
  cat > "$LEARNING_LOOP_REPORT_PATH" <<'JSON'
{
  "apply_supported": false,
  "generated_at": "2026-01-01T00:00:00Z",
  "human_review_required": true,
  "observations": [
    "Analyzed 3 aggregate feedback records."
  ],
  "recommendations": [
    {
      "apply_supported": false,
      "category": "router",
      "human_review_required": true,
      "reason": "One router intent dominates the feedback summary.",
      "suggested_review": "Add human-reviewed docs or tests for this intent before changing router config.",
      "title": "Add review examples for router intent 'architecture'"
    },
    {
      "apply_supported": false,
      "category": "tests",
      "human_review_required": true,
      "reason": "The top tags include 'tests'.",
      "suggested_review": "Create a human-reviewed follow-up task; keep this report advisory only.",
      "title": "Add or refine tests for repeated feedback themes"
    }
  ],
  "service": "learning-loop-report",
  "source_record_count": 3,
  "source_summary_path": "/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json"
}
JSON
  pass "created minimal runtime learning-loop report"
else
  pass "using existing runtime learning-loop report"
fi

make -C "$ROOT" improvement-plan-local

[ -f "$IMPROVEMENT_PLAN_PATH" ] || fail "missing improvement plan: $IMPROVEMENT_PLAN_PATH"
pass "improvement plan exists under runtime"

python3 - "$ROOT" "$IMPROVEMENT_PLAN_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
plan_path = pathlib.Path(sys.argv[2]).resolve()
plan = json.loads(plan_path.read_text(encoding="utf-8"))

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in plan_path.parents:
    fail(f"plan was written inside the repository: {plan_path}")
if plan.get("apply_supported") is not False:
    fail(f"apply_supported must be false: {plan}")
if plan.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {plan}")
if plan.get("plan_status") != "review_required":
    fail(f"plan_status must be review_required: {plan}")
if not plan.get("proposed_changes"):
    fail(f"proposed_changes must not be empty: {plan}")
for change in plan["proposed_changes"]:
    if change.get("apply_supported") is not False:
        fail(f"proposed change apply_supported must be false: {change}")
    if change.get("human_approval_required") is not True:
        fail(f"proposed change human_approval_required must be true: {change}")
for forbidden in ("prompt", "response", "records", "feedback_records"):
    if forbidden in plan:
        fail(f"forbidden raw field present: {forbidden}")
serialized = json.dumps(plan, sort_keys=True).lower()
for forbidden_text in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text"):
    if forbidden_text in serialized:
        fail(f"forbidden raw text marker present: {forbidden_text}")
print("PASS: improvement plan contract is safe")
PY

if find "$ROOT" -name "human-approved-improvement-plan.json" -print -quit | grep -q .; then
  fail "human-approved-improvement-plan.json was written inside the repository"
fi
pass "no improvement plan output was written into the repo"

echo "Improvement plan tests passed"
