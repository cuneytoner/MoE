#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
PLAN_SCRIPT="$ROOT/scripts/memory-store-plan-local.sh"
STORE_SCRIPT="$ROOT/scripts/memory-store-approved.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$PLAN_SCRIPT" ] || fail "missing script: $PLAN_SCRIPT"
[ -x "$PLAN_SCRIPT" ] || fail "script is not executable: $PLAN_SCRIPT"
[ -f "$STORE_SCRIPT" ] || fail "missing script: $STORE_SCRIPT"
[ -x "$STORE_SCRIPT" ] || fail "script is not executable: $STORE_SCRIPT"
pass "memory store scripts exist and are executable"

if [ ! -f "$FEEDBACK_MEMORY_CANDIDATES_PATH" ]; then
  mkdir -p "$(dirname "$FEEDBACK_MEMORY_CANDIDATES_PATH")"
  printf '%s\n' '{"service":"feedback-memory-candidate-review","candidate_status":"pending_human_review","memory_write_supported":false,"human_review_required":true,"candidates":[{"id":"memory-candidate-test-001","category":"workflow","title":"Store only reviewed lessons","proposed_memory_text":"Only store stable project-level memory candidates after explicit human approval.","rationale":"Test fixture for memory store workflow.","source_reports":["test"],"confidence":0.8,"risk":"low","approval_required":true,"memory_write_supported":false}],"rejected_or_blocked_candidates":[]}' > "$FEEDBACK_MEMORY_CANDIDATES_PATH"
  pass "created minimal runtime feedback memory candidates"
else
  pass "using existing runtime feedback memory candidates"
fi

make -C "$ROOT" memory-store-plan-local

[ -f "$MEMORY_STORE_PLAN_PATH" ] || fail "missing memory store plan: $MEMORY_STORE_PLAN_PATH"
pass "memory store plan exists under runtime"

python3 - "$ROOT" "$MEMORY_STORE_PLAN_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
plan_path = pathlib.Path(sys.argv[2]).resolve()
plan = json.loads(plan_path.read_text(encoding="utf-8"))

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in plan_path.parents:
    fail(f"memory store plan was written inside the repository: {plan_path}")
if plan.get("memory_write_supported") is not False:
    fail("memory_write_supported must be false")
if plan.get("apply_supported") is not False:
    fail("apply_supported must be false")
if plan.get("human_review_required") is not True:
    fail("human_review_required must be true")
if plan.get("plan_status") != "pending_human_approval":
    fail("plan_status must be pending_human_approval")
if not isinstance(plan.get("approved_candidates"), list):
    fail("approved_candidates must be a list")
if not isinstance(plan.get("blocked_candidates"), list):
    fail("blocked_candidates must be a list")
if not isinstance(plan.get("manual_store_commands"), list):
    fail("manual_store_commands must be a list")
serialized = json.dumps(plan, sort_keys=True).lower()
for forbidden in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text", "feedback_records"):
    if forbidden in serialized:
        fail(f"forbidden raw content marker present: {forbidden}")
print("PASS: memory store plan contract is safe")
PY

dry_run_output="$(
  MEMORY_API_URL="http://127.0.0.1:1" make -C "$ROOT" memory-store-approved
)"
printf '%s\n' "$dry_run_output"
if ! grep -q "DRY-RUN\|SKIP: No approved memory candidates" <<<"$dry_run_output"; then
  fail "memory-store-approved did not run in dry-run or graceful skip mode"
fi
pass "dry-run did not require reachable Memory API"

if find "$ROOT" -name "memory-store-plan.json" -print -quit | grep -q .; then
  fail "memory-store-plan.json was written inside the repository"
fi
pass "no memory store plan output was written into the repo"

echo "Memory store workflow tests passed"
