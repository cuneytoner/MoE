#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"
LEARNING_LOOP_REPORT_PATH="${LEARNING_LOOP_REPORT_PATH:-${RUNTIME_DIR}/reports/learning-loop/learning-loop-report.json}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"
ROUTER_PROMPT_APPROVAL_PATH="${ROUTER_PROMPT_APPROVAL_PATH:-${RUNTIME_DIR}/reports/approvals/router-prompt-update-approval-packet.json}"
FEEDBACK_MEMORY_CANDIDATES_PATH="${FEEDBACK_MEMORY_CANDIDATES_PATH:-${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json}"
SCRIPT="$ROOT/scripts/feedback-memory-candidates-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "feedback memory candidates script exists and is executable"

if [ ! -f "$FEEDBACK_SUMMARY_PATH" ]; then
  mkdir -p "$(dirname "$FEEDBACK_SUMMARY_PATH")"
  printf '%s\n' '{"record_count":3,"rating_counts":{"useful":2,"not_useful":1},"router_intent_counts":{"code":3},"model_counts":{"coder":3},"top_tags":[{"tag":"tests","count":2}]}' > "$FEEDBACK_SUMMARY_PATH"
  pass "created minimal runtime feedback summary"
else
  pass "using existing runtime feedback summary"
fi

if [ ! -f "$LEARNING_LOOP_REPORT_PATH" ]; then
  mkdir -p "$(dirname "$LEARNING_LOOP_REPORT_PATH")"
  printf '%s\n' '{"service":"learning-loop-report","source_record_count":3,"recommendations":[{"category":"stability","title":"Preserve useful behavior","reason":"Aggregate ratings are useful.","suggested_review":"Add tests first."}],"apply_supported":false,"human_review_required":true}' > "$LEARNING_LOOP_REPORT_PATH"
  pass "created minimal runtime learning-loop report"
else
  pass "using existing runtime learning-loop report"
fi

if [ ! -f "$IMPROVEMENT_PLAN_PATH" ]; then
  mkdir -p "$(dirname "$IMPROVEMENT_PLAN_PATH")"
  printf '%s\n' '{"service":"human-approved-improvement-plan","plan_status":"review_required","proposed_changes":[{"category":"tests","title":"Add regression tests","risk":"low"}],"apply_supported":false,"human_review_required":true}' > "$IMPROVEMENT_PLAN_PATH"
  pass "created minimal runtime improvement plan"
else
  pass "using existing runtime improvement plan"
fi

if [ ! -f "$ROUTER_PROMPT_APPROVAL_PATH" ]; then
  mkdir -p "$(dirname "$ROUTER_PROMPT_APPROVAL_PATH")"
  printf '%s\n' '{"service":"router-prompt-update-approval","approval_status":"pending_human_review","approval_items":[{"id":"approval-001","category":"router","title":"Review routing examples","risk":"medium"}],"blocked_items":[],"apply_supported":false,"human_review_required":true}' > "$ROUTER_PROMPT_APPROVAL_PATH"
  pass "created minimal runtime router/prompt approval packet"
else
  pass "using existing runtime router/prompt approval packet"
fi

make -C "$ROOT" feedback-memory-candidates-local

[ -f "$FEEDBACK_MEMORY_CANDIDATES_PATH" ] || fail "missing memory candidate review: $FEEDBACK_MEMORY_CANDIDATES_PATH"
pass "memory candidate review exists under runtime"

python3 - "$ROOT" "$FEEDBACK_MEMORY_CANDIDATES_PATH" "$SCRIPT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
report_path = pathlib.Path(sys.argv[2]).resolve()
script_path = pathlib.Path(sys.argv[3])
report = json.loads(report_path.read_text(encoding="utf-8"))
script_text = script_path.read_text(encoding="utf-8").lower()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in report_path.parents:
    fail(f"memory candidate review was written inside the repository: {report_path}")
if report.get("memory_write_supported") is not False:
    fail(f"memory_write_supported must be false: {report}")
if report.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {report}")
if report.get("candidate_status") != "pending_human_review":
    fail(f"candidate_status must be pending_human_review: {report}")
if not isinstance(report.get("candidates"), list):
    fail(f"candidates must be a list: {report}")
if not isinstance(report.get("rejected_or_blocked_candidates"), list):
    fail(f"rejected_or_blocked_candidates must be a list: {report}")
for candidate in report["candidates"]:
    if candidate.get("memory_write_supported") is not False:
        fail(f"candidate memory_write_supported must be false: {candidate}")
    if candidate.get("approval_required") is not True:
        fail(f"candidate approval_required must be true: {candidate}")
    if not 0 <= candidate.get("confidence", -1) <= 1:
        fail(f"candidate confidence must be between 0 and 1: {candidate}")
for forbidden in ("prompt", "response", "records", "feedback_records"):
    if forbidden in report:
        fail(f"forbidden raw field present at top level: {forbidden}")
serialized = json.dumps(report, sort_keys=True).lower()
for forbidden_text in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text"):
    if forbidden_text in serialized:
        fail(f"forbidden raw text marker present: {forbidden_text}")
for call_marker in ("curl ", "requests.", "urllib.request", "/memory/add", "/memory/search"):
    if call_marker in script_text:
        fail(f"script appears to call an external service: {call_marker}")
print("PASS: feedback memory candidate review contract is safe")
PY

if find "$ROOT" -name "feedback-memory-candidates.json" -print -quit | grep -q .; then
  fail "feedback-memory-candidates.json was written inside the repository"
fi
pass "no memory candidate output was written into the repo"

echo "Feedback memory candidate tests passed"
