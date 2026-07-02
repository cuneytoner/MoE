#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
MEMORY_STORE_APPLY_LOG_PATH="${MEMORY_STORE_DIR}/memory-store-apply-log.jsonl"
MEMORY_STORE_APPLY_SUMMARY_PATH="${MEMORY_STORE_DIR}/memory-store-apply-summary.json"
STORE_SCRIPT="$ROOT/scripts/memory-store-approved.sh"
STATUS_SCRIPT="$ROOT/scripts/memory-store-apply-log-status.sh"
test_tmp_dir="$(mktemp -d /tmp/moe-memory-store-apply-log-test.XXXXXX)"
plan_backup_path="${test_tmp_dir}/memory-store-plan.json"
plan_existed=0

cleanup() {
  if [ "$plan_existed" = "1" ]; then
    cp "$plan_backup_path" "$MEMORY_STORE_PLAN_PATH"
  else
    rm -f "$MEMORY_STORE_PLAN_PATH"
  fi
  rm -rf "$test_tmp_dir"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$STORE_SCRIPT" ] || fail "missing script: $STORE_SCRIPT"
[ -x "$STORE_SCRIPT" ] || fail "script is not executable: $STORE_SCRIPT"
[ -f "$STATUS_SCRIPT" ] || fail "missing script: $STATUS_SCRIPT"
[ -x "$STATUS_SCRIPT" ] || fail "script is not executable: $STATUS_SCRIPT"
pass "memory store apply log scripts exist and are executable"

mkdir -p "$MEMORY_STORE_DIR"
if [ -f "$MEMORY_STORE_PLAN_PATH" ]; then
  cp "$MEMORY_STORE_PLAN_PATH" "$plan_backup_path"
  plan_existed=1
fi

before_count=0
if [ -f "$MEMORY_STORE_APPLY_LOG_PATH" ]; then
  before_count="$(wc -l < "$MEMORY_STORE_APPLY_LOG_PATH")"
fi

cat > "$MEMORY_STORE_PLAN_PATH" <<'JSON'
{
  "service": "human-approved-memory-store-plan",
  "plan_status": "pending_human_approval",
  "memory_write_supported": false,
  "apply_supported": false,
  "human_review_required": true,
  "memory_api_url": "http://127.0.0.1:8101",
  "approved_candidates": [
    {
      "id": "memory-candidate-apply-log-001",
      "category": "workflow",
      "title": "Store only approved lessons",
      "proposed_memory_text": "Store only stable project-level memory candidates after explicit approval.",
      "rationale": "Test fixture for apply log workflow.",
      "confidence": 0.8,
      "risk": "low",
      "approval_required": true,
      "memory_write_supported": false
    }
  ],
  "blocked_candidates": [],
  "manual_store_commands": []
}
JSON
pass "created minimal runtime memory store plan with one approved candidate"

dry_run_output="$(
  MEMORY_API_URL="http://127.0.0.1:1" make -C "$ROOT" memory-store-approved
)"
printf '%s\n' "$dry_run_output"
if ! grep -q "DRY-RUN" <<<"$dry_run_output"; then
  fail "memory-store-approved did not run in dry-run mode"
fi
after_plain_count=0
if [ -f "$MEMORY_STORE_APPLY_LOG_PATH" ]; then
  after_plain_count="$(wc -l < "$MEMORY_STORE_APPLY_LOG_PATH")"
fi
if [ "$after_plain_count" -ne "$before_count" ]; then
  fail "dry-run without LOG_DRY_RUN wrote apply-log entries"
fi
pass "dry-run without LOG_DRY_RUN did not append apply log"

LOG_DRY_RUN=1 MEMORY_API_URL="http://127.0.0.1:1" make -C "$ROOT" memory-store-approved

[ -f "$MEMORY_STORE_APPLY_LOG_PATH" ] || fail "missing apply log: $MEMORY_STORE_APPLY_LOG_PATH"
[ -f "$MEMORY_STORE_APPLY_SUMMARY_PATH" ] || fail "missing apply summary: $MEMORY_STORE_APPLY_SUMMARY_PATH"
pass "apply log and summary exist under runtime"

python3 - "$ROOT" "$MEMORY_STORE_APPLY_LOG_PATH" "$MEMORY_STORE_APPLY_SUMMARY_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
log_path = pathlib.Path(sys.argv[2]).resolve()
summary_path = pathlib.Path(sys.argv[3]).resolve()

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in log_path.parents:
    fail(f"apply log was written inside the repository: {log_path}")
if root in summary_path.parents:
    fail(f"apply summary was written inside the repository: {summary_path}")

entries = [
    json.loads(line)
    for line in log_path.read_text(encoding="utf-8").splitlines()
    if line.strip()
]
latest = entries[-1]
if latest.get("mode") != "dry_run":
    fail(f"latest log entry should be dry_run: {latest}")
if latest.get("result") != "skipped":
    fail(f"latest log entry should be skipped: {latest}")
if latest.get("apply_requested") is not False:
    fail(f"dry-run apply_requested must be false: {latest}")
if latest.get("raw_prompt_included") is not False:
    fail(f"raw_prompt_included must be false: {latest}")
if latest.get("raw_response_included") is not False:
    fail(f"raw_response_included must be false: {latest}")
if "proposed_memory_text" in latest:
    fail("apply log must not include proposed_memory_text")

summary = json.loads(summary_path.read_text(encoding="utf-8"))
if summary.get("dry_run_count", 0) < 1:
    fail(f"dry_run_count must be >= 1: {summary}")
if summary.get("raw_prompt_included") is not False:
    fail(f"summary raw_prompt_included must be false: {summary}")
if summary.get("raw_response_included") is not False:
    fail(f"summary raw_response_included must be false: {summary}")
if summary.get("human_review_required") is not True:
    fail(f"summary human_review_required must be true: {summary}")
print("PASS: memory store apply log contract is safe")
PY

make -C "$ROOT" memory-store-apply-log-status

if find "$ROOT" \( -name "memory-store-apply-log.jsonl" -o -name "memory-store-apply-summary.json" \) -print -quit | grep -q .; then
  fail "memory store apply log output was written inside the repository"
fi
pass "no memory store apply log output was written into the repo"

echo "Memory store apply log tests passed"
