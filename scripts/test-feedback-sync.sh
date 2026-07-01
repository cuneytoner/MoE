#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS_SCRIPT="$ROOT/scripts/feedback-sync-status.sh"
SYNC_SCRIPT="$ROOT/scripts/feedback-sync-to-pc2.sh"
TEST_DIR="$(mktemp -d /tmp/moe-feedback-sync-test.XXXXXX)"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

for script in "$STATUS_SCRIPT" "$SYNC_SCRIPT"; do
  [ -f "$script" ] || fail "missing script: $script"
  [ -x "$script" ] || fail "script is not executable: $script"
done
pass "feedback sync scripts exist and are executable"

mkdir -p "$TEST_DIR/reports"
printf '%s\n' '{"created_at":"2026-01-01T00:00:00Z","rating":"useful","source":"manual"}' > "$TEST_DIR/gateway-feedback.jsonl"
printf '%s\n' '{"record_count":1}' > "$TEST_DIR/reports/feedback-summary.json"

status_output="$(
  PC2_HOST="127.0.0.1" \
  PC2_FEEDBACK_DIR="/tmp/moe-feedback-sync-test-pc2" \
  FEEDBACK_JSONL_PATH="$TEST_DIR/gateway-feedback.jsonl" \
  "$STATUS_SCRIPT" 2>&1 || true
)"
if ! grep -q "PC1 Gateway feedback" <<<"$status_output"; then
  fail "feedback-sync-status did not print PC1 feedback status: $status_output"
fi
pass "feedback-sync-status runs without requiring PC2 availability"

dry_run_output="$(
  PC2_HOST="127.0.0.1" \
  PC2_FEEDBACK_DIR="/tmp/moe-feedback-sync-test-pc2" \
  FEEDBACK_JSONL_PATH="$TEST_DIR/gateway-feedback.jsonl" \
  FEEDBACK_REPORTS_DIR="$TEST_DIR/reports" \
  "$SYNC_SCRIPT" 2>&1 || true
)"
if ! grep -q "DRY RUN" <<<"$dry_run_output"; then
  fail "feedback-sync-to-pc2 did not default to dry-run: $dry_run_output"
fi
if grep -q "Permission denied\|Connection refused\|No route to host" <<<"$dry_run_output"; then
  fail "dry-run attempted to contact PC2: $dry_run_output"
fi
pass "feedback-sync-to-pc2 dry-run does not require PC2 availability"

for script in "$STATUS_SCRIPT" "$SYNC_SCRIPT"; do
  forbidden_delete="-""-delete"
  if grep -q -- "$forbidden_delete" "$script"; then
    fail "forbidden rsync deletion flag found in ${script#$ROOT/}"
  fi

  model_root="/home/cuneyt/MoE_Models""_Backup"
  if grep -q -- "$model_root" "$script"; then
    fail "model backup path referenced in ${script#$ROOT/}"
  fi

  media_outputs="media""/outputs"
  if grep -q -- "$media_outputs" "$script"; then
    fail "media output path referenced in ${script#$ROOT/}"
  fi
done
pass "feedback sync scripts avoid deletion, model paths, and media outputs"

echo "Feedback sync tests passed"
