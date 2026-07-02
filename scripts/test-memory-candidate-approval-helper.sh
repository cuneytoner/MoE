#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_CANDIDATES_DIR="${RUNTIME_DIR}/reports/memory-candidates"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
FEEDBACK_MEMORY_CANDIDATES_PATH="${MEMORY_CANDIDATES_DIR}/feedback-memory-candidates.json"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
MEMORY_STORE_AUDIT_PATH="${MEMORY_STORE_DIR}/memory-store-audit.json"
APPROVED_MEMORY_CANDIDATES_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
EXAMPLE_APPROVAL_FILE_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.example.json"
HELPER_REPORT_PATH="${MEMORY_STORE_DIR}/memory-candidate-approval-helper-report.json"
HELPER_SCRIPT="$ROOT/scripts/memory-candidate-approval-helper-local.sh"
LIST_SCRIPT="$ROOT/scripts/memory-candidate-list-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$HELPER_SCRIPT" ] || fail "missing script: $HELPER_SCRIPT"
[ -x "$HELPER_SCRIPT" ] || fail "script is not executable: $HELPER_SCRIPT"
[ -f "$LIST_SCRIPT" ] || fail "missing script: $LIST_SCRIPT"
[ -x "$LIST_SCRIPT" ] || fail "script is not executable: $LIST_SCRIPT"
pass "memory candidate approval helper scripts exist and are executable"

mkdir -p "$MEMORY_CANDIDATES_DIR" "$MEMORY_STORE_DIR"
approval_existed=0
if [ -f "$APPROVED_MEMORY_CANDIDATES_PATH" ]; then
  approval_existed=1
fi

if [ ! -f "$FEEDBACK_MEMORY_CANDIDATES_PATH" ]; then
  cat > "$FEEDBACK_MEMORY_CANDIDATES_PATH" <<'JSON'
{
  "service": "feedback-memory-candidate-review",
  "memory_write_supported": false,
  "human_review_required": true,
  "candidates": [
    {
      "id": "memory-candidate-helper-001",
      "category": "workflow",
      "title": "Review memory candidates before approval",
      "proposed_memory_text": "Memory candidates require manual review before they can be added to the approval file.",
      "confidence": 0.82,
      "risk": "low",
      "approval_required": true,
      "memory_write_supported": false
    }
  ]
}
JSON
  pass "created minimal feedback memory candidates fixture"
else
  pass "using existing runtime feedback memory candidates"
fi

if [ ! -f "$MEMORY_STORE_PLAN_PATH" ]; then
  cat > "$MEMORY_STORE_PLAN_PATH" <<'JSON'
{
  "service": "human-approved-memory-store-plan",
  "approved_candidates": [],
  "blocked_candidates": [
    {
      "id": "memory-candidate-helper-001",
      "category": "workflow",
      "title": "Review memory candidates before approval",
      "blocked_reason": "missing explicit human approval",
      "memory_write_supported": false,
      "human_review_required": true
    }
  ],
  "memory_write_supported": false,
  "apply_supported": false,
  "human_review_required": true
}
JSON
  pass "created minimal memory store plan fixture"
else
  pass "using existing runtime memory store plan"
fi

if [ ! -f "$MEMORY_STORE_AUDIT_PATH" ]; then
  cat > "$MEMORY_STORE_AUDIT_PATH" <<'JSON'
{
  "service": "memory-store-audit",
  "audit_status": "review_required",
  "counts": {
    "approved_count": 0,
    "blocked_count": 1,
    "pending_count": 0,
    "duplicate_group_count": 0,
    "duplicate_candidate_count": 0,
    "unique_group_count": 1
  },
  "duplicate_groups": [],
  "memory_write_supported": false,
  "apply_supported": false,
  "human_review_required": true
}
JSON
  pass "created minimal memory store audit fixture"
else
  pass "using existing runtime memory store audit"
fi

make -C "$ROOT" memory-candidate-approval-helper-local

[ -f "$HELPER_REPORT_PATH" ] || fail "missing helper report: $HELPER_REPORT_PATH"
[ -f "$EXAMPLE_APPROVAL_FILE_PATH" ] || fail "missing example approval file: $EXAMPLE_APPROVAL_FILE_PATH"
if [ "$approval_existed" = "0" ] && [ -f "$APPROVED_MEMORY_CANDIDATES_PATH" ]; then
  fail "helper created real approval file: $APPROVED_MEMORY_CANDIDATES_PATH"
fi
pass "helper wrote report and example approval file without creating real approval file"

python3 - "$ROOT" "$HELPER_REPORT_PATH" "$EXAMPLE_APPROVAL_FILE_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
report_path = pathlib.Path(sys.argv[2]).resolve()
example_path = pathlib.Path(sys.argv[3]).resolve()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in report_path.parents:
    fail(f"helper report was written inside the repository: {report_path}")
if root in example_path.parents:
    fail(f"example approval file was written inside the repository: {example_path}")

report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("auto_approval_supported") is not False:
    fail(f"auto_approval_supported must be false: {report}")
if report.get("memory_write_supported") is not False:
    fail(f"memory_write_supported must be false: {report}")
if report.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {report}")
if not isinstance(report.get("candidate_cards"), list):
    fail("candidate_cards must be a list")
serialized = json.dumps(report).lower()
for forbidden in ("raw_prompt", "raw_response", "prompt_text", "response_text", "memory/add"):
    if forbidden in serialized:
        fail(f"helper report contains forbidden field/content: {forbidden}")

example = json.loads(example_path.read_text(encoding="utf-8"))
if example.get("approved_candidate_ids") != []:
    fail(f"example approval file must start with empty approved_candidate_ids: {example}")
print("PASS: memory candidate approval helper contract is safe")
PY

list_output="$(make -C "$ROOT" memory-candidate-list-local)"
printf '%s\n' "$list_output"
if ! grep -q "id | category | risk | status | duplicate? | title" <<<"$list_output"; then
  fail "candidate list did not print expected table header"
fi
pass "memory candidate list printed compact table"

if find "$ROOT" \( -name "memory-candidate-approval-helper-report.json" -o -name "approved-memory-candidates.example.json" \) -print -quit | grep -q .; then
  fail "memory candidate helper output was written inside the repository"
fi
pass "no memory candidate helper output was written into the repo"

echo "Memory candidate approval helper tests passed"
