#!/usr/bin/env bash
set -euo pipefail

SCRIPT="scripts/memory-store-manual-preflight.sh"
RUNBOOK="docs/memory-approval-manual-store-runbook.md"
APPROVAL_FILE="/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json"
RUNTIME_DIR="/home/cuneyt/MoE/runtime/reports/memory-store"

fail() {
  echo "FAIL: $*"
  exit 1
}

pass() {
  echo "PASS: $*"
}

snapshot_file_state() {
  local path="$1"

  if [[ -f "$path" ]]; then
    stat -c '%s:%Y' "$path"
  else
    echo "__missing__"
  fi
}

echo "Testing memory store manual preflight"

[[ -f "$SCRIPT" ]] || fail "$SCRIPT does not exist"
[[ -x "$SCRIPT" ]] || fail "$SCRIPT is not executable"
bash -n "$SCRIPT"
pass "preflight script exists, is executable, and has valid bash syntax"

[[ -f "$RUNBOOK" ]] || fail "$RUNBOOK does not exist"
grep -q '^## Safety boundaries' "$RUNBOOK" || fail "runbook missing Safety boundaries heading"
grep -q 'APPLY=1 make memory-store-approved' "$RUNBOOK" || fail "runbook missing manual APPLY=1 command"
grep -q 'Tests must never run this command' "$RUNBOOK" || fail "runbook does not state tests never run APPLY=1"
pass "runbook safety content exists"

if grep -Eq '/memory/add|/memory/search|MEMORY_API_URL' "$SCRIPT"; then
  fail "preflight script contains forbidden Memory API write/search wiring"
fi
pass "preflight script contains no forbidden Memory API wiring"

if grep -Eq 'APPLY=1[[:space:]]+make memory-store-approved|APPLY=1.*memory-store-approved' "$SCRIPT"; then
  fail "preflight script contains an internal APPLY=1 execution"
fi
pass "preflight script does not execute APPLY=1"

if awk '/^[[:space:]]*APPLY=1[[:space:]]+make[[:space:]]+memory-store-approved/ { found=1 } END { exit found ? 0 : 1 }' "$0"; then
  fail "test script contains a real APPLY=1 execution line"
fi
pass "test script does not execute APPLY=1"

before_approval_state="$(snapshot_file_state "$APPROVAL_FILE")"

before_runtime_listing="$(mktemp)"
after_runtime_listing="$(mktemp)"
cleanup() {
  rm -f "$before_runtime_listing" "$after_runtime_listing"
}
trap cleanup EXIT

if [[ -d "$RUNTIME_DIR" ]]; then
  find "$RUNTIME_DIR" -maxdepth 1 -type f -printf '%f:%s:%T@\n' | sort > "$before_runtime_listing"
else
  : > "$before_runtime_listing"
fi

make memory-store-manual-preflight

after_approval_state="$(snapshot_file_state "$APPROVAL_FILE")"

if [[ "$before_approval_state" != "$after_approval_state" ]]; then
  fail "preflight modified or created approved-memory-candidates.json"
fi
pass "preflight does not modify approved-memory-candidates.json"

if [[ -d "$RUNTIME_DIR" ]]; then
  find "$RUNTIME_DIR" -maxdepth 1 -type f -printf '%f:%s:%T@\n' | sort > "$after_runtime_listing"
else
  : > "$after_runtime_listing"
fi

if ! diff -u "$before_runtime_listing" "$after_runtime_listing" >/dev/null; then
  fail "preflight modified runtime report files"
fi
pass "preflight writes no runtime reports"

git_before="$(git status --porcelain)"
make memory-store-manual-preflight >/tmp/memory-store-manual-preflight-test.out
git_after="$(git status --porcelain)"

if [[ "$git_before" != "$git_after" ]]; then
  fail "preflight changed repository working tree"
fi
pass "preflight writes no generated output into repo"

echo
echo "PASS: memory store manual preflight test completed"
