#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
MEMORY_STORE_AUDIT_PATH="${MEMORY_STORE_DIR}/memory-store-audit.json"
SCRIPT="$ROOT/scripts/memory-store-audit-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "memory store audit script exists and is executable"

if [ ! -f "$MEMORY_STORE_PLAN_PATH" ]; then
  mkdir -p "$MEMORY_STORE_DIR"
  printf '%s\n' '{"service":"human-approved-memory-store-plan","plan_status":"pending_human_approval","memory_write_supported":false,"apply_supported":false,"human_review_required":true,"approved_candidates":[],"blocked_candidates":[{"id":"memory-candidate-test-001","category":"workflow","title":"Preserve current useful behavior","blocked_reason":"missing explicit human approval"},{"id":"memory-candidate-test-002","category":"workflow","title":"Preserve current useful behavior!","blocked_reason":"missing explicit human approval"}],"pending_candidates":[]}' > "$MEMORY_STORE_PLAN_PATH"
  pass "created minimal runtime memory store plan with duplicates"
else
  pass "using existing runtime memory store plan"
fi

make -C "$ROOT" memory-store-audit-local

[ -f "$MEMORY_STORE_AUDIT_PATH" ] || fail "missing memory store audit: $MEMORY_STORE_AUDIT_PATH"
pass "memory store audit exists under runtime"

python3 - "$ROOT" "$MEMORY_STORE_AUDIT_PATH" "$SCRIPT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
audit_path = pathlib.Path(sys.argv[2]).resolve()
script_path = pathlib.Path(sys.argv[3])
audit = json.loads(audit_path.read_text(encoding="utf-8"))
script_text = script_path.read_text(encoding="utf-8").lower()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in audit_path.parents:
    fail(f"memory store audit was written inside the repository: {audit_path}")
if audit.get("memory_write_supported") is not False:
    fail("memory_write_supported must be false")
if audit.get("apply_supported") is not False:
    fail("apply_supported must be false")
if audit.get("human_review_required") is not True:
    fail("human_review_required must be true")
if audit.get("audit_status") != "review_required":
    fail("audit_status must be review_required")
if not isinstance(audit.get("duplicate_groups"), list):
    fail("duplicate_groups must be a list")
if not isinstance(audit.get("counts"), dict):
    fail("counts must be an object")
serialized = json.dumps(audit, sort_keys=True).lower()
for forbidden in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text", "feedback_records"):
    if forbidden in serialized:
        fail(f"forbidden raw content marker present: {forbidden}")
for call_marker in ("curl ", "requests.", "urllib.request", "/memory/add", "/memory/search"):
    if call_marker in script_text:
        fail(f"script appears to call an external service: {call_marker}")
print("PASS: memory store audit contract is safe")
PY

if find "$ROOT" -name "memory-store-audit.json" -print -quit | grep -q .; then
  fail "memory-store-audit.json was written inside the repository"
fi
pass "no memory store audit output was written into the repo"

echo "Memory store audit tests passed"
