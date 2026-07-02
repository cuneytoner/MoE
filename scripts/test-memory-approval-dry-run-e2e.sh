#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
E2E_REPORT_PATH="${MEMORY_STORE_DIR}/memory-approval-dry-run-e2e-report.json"
APPROVAL_FILE_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
E2E_SCRIPT="$ROOT/scripts/memory-approval-dry-run-e2e-local.sh"
STATUS_SCRIPT="$ROOT/scripts/memory-approval-dry-run-e2e-status.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$E2E_SCRIPT" ] || fail "missing script: $E2E_SCRIPT"
[ -x "$E2E_SCRIPT" ] || fail "script is not executable: $E2E_SCRIPT"
[ -f "$STATUS_SCRIPT" ] || fail "missing script: $STATUS_SCRIPT"
[ -x "$STATUS_SCRIPT" ] || fail "script is not executable: $STATUS_SCRIPT"
pass "memory approval dry-run E2E scripts exist and are executable"

if grep -R "^[[:space:]]*APPLY=1[[:space:]]" "$E2E_SCRIPT" "$STATUS_SCRIPT"; then
  fail "E2E scripts must not invoke APPLY=1 internally"
fi
if grep -R "curl .*memory" "$E2E_SCRIPT" "$STATUS_SCRIPT"; then
  fail "E2E scripts must not call Memory API directly"
fi
pass "E2E scripts do not invoke APPLY=1 or direct Memory API calls"

approval_existed=0
approval_was_test_fixture=0
if [ -f "$APPROVAL_FILE_PATH" ]; then
  approval_existed=1
  approval_was_test_fixture="$(jq -r '.test_fixture // false' "$APPROVAL_FILE_PATH" 2>/dev/null || echo "false")"
fi

make -C "$ROOT" memory-approval-dry-run-e2e-local
[ -f "$E2E_REPORT_PATH" ] || fail "missing E2E report: $E2E_REPORT_PATH"

python3 - "$ROOT" "$E2E_REPORT_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
report_path = pathlib.Path(sys.argv[2]).resolve()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in report_path.parents:
    fail(f"E2E report was written inside the repository: {report_path}")
report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("dry_run_only") is not True:
    fail(f"dry_run_only must be true: {report}")
if report.get("apply_used") is not False:
    fail(f"apply_used must be false: {report}")
if report.get("memory_write_supported") is not False:
    fail(f"memory_write_supported must be false: {report}")
if report.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {report}")
serialized = json.dumps(report).lower()
for forbidden in ("raw_prompt", "raw_response", "prompt_text", "response_text"):
    if forbidden in serialized:
        fail(f"E2E report contains forbidden raw field/content: {forbidden}")
print("PASS: no-fixture E2E report contract is safe")
PY

USE_TEST_APPROVAL_FIXTURE=1 make -C "$ROOT" memory-approval-dry-run-e2e-local

python3 - "$ROOT" "$E2E_REPORT_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
report_path = pathlib.Path(sys.argv[2]).resolve()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("test_approval_fixture_used") is not True:
    fail(f"test_approval_fixture_used must be true: {report}")
if report.get("stored_count") != 0:
    fail(f"stored_count must stay zero in dry-run E2E: {report}")
if report.get("apply_used") is not False:
    fail(f"apply_used must be false: {report}")
if report.get("memory_write_supported") is not False:
    fail(f"memory_write_supported must be false: {report}")
print("PASS: fixture E2E report contract is safe")
PY

if [ "$approval_existed" = "0" ] && [ -f "$APPROVAL_FILE_PATH" ]; then
  fail "test approval fixture was not removed: $APPROVAL_FILE_PATH"
fi
if [ "$approval_existed" = "1" ] && [ "$approval_was_test_fixture" != "true" ]; then
  if [ ! -f "$APPROVAL_FILE_PATH" ]; then
    fail "pre-existing non-test approval file was removed"
  fi
fi
pass "no unintended real approval file remains"

make -C "$ROOT" memory-approval-dry-run-e2e-status

if find "$ROOT" -name "memory-approval-dry-run-e2e-report.json" -print -quit | grep -q .; then
  fail "E2E report was written inside the repository"
fi
pass "no memory approval E2E output was written into the repo"

echo "Memory approval dry-run E2E tests passed"
