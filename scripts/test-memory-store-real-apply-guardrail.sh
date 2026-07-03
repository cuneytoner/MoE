#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/memory-store-real-apply-guardrail.sh"
STORE_SCRIPT="$ROOT/scripts/memory-store-approved.sh"
test_tmp_dir="$(mktemp -d /tmp/moe-memory-store-real-apply-guardrail-test.XXXXXX)"

cleanup() {
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

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
bash -n "$SCRIPT"
pass "guardrail script exists, is executable, and has valid bash syntax"

[ -f "$STORE_SCRIPT" ] || fail "missing store script: $STORE_SCRIPT"

if grep -Eq '/memory/add|/memory/search|MEMORY_API_URL|curl|gateway|Gateway|llama-server|LLAMA' "$SCRIPT"; then
  fail "guardrail script contains forbidden service/API wiring"
fi
pass "guardrail script contains no Memory API, Gateway, llama-server, or curl wiring"

if grep -Eq '(^|[[:space:]])APPLY=1[[:space:]]+(make|./scripts/memory-store-approved|scripts/memory-store-approved)' "$SCRIPT"; then
  fail "guardrail script contains an APPLY=1 execution"
fi
pass "guardrail script does not execute APPLY=1"

guard_line="$(grep -n 'memory-store-real-apply-guardrail.sh' "$STORE_SCRIPT" | head -n 1 | cut -d: -f1)"
apply_echo_line="$(grep -n 'APPLY=1: storing approved memory candidates' "$STORE_SCRIPT" | head -n 1 | cut -d: -f1)"
curl_line="$(grep -n '^[[:space:]]*curl -sS' "$STORE_SCRIPT" | tail -n 1 | cut -d: -f1)"

if [[ -z "$guard_line" || -z "$apply_echo_line" || -z "$curl_line" ]]; then
  fail "could not locate guardrail, apply marker, or real curl path in memory-store-approved.sh"
fi

if [[ "$guard_line" -ge "$apply_echo_line" || "$guard_line" -ge "$curl_line" ]]; then
  fail "guardrail must run before the real apply curl path"
fi
pass "memory-store-approved.sh calls guardrail before the real apply curl path"

if awk '/^[[:space:]]*APPLY=1[[:space:]]+make[[:space:]]+memory-store-approved/ { found=1 } END { exit found ? 0 : 1 }' "$0"; then
  fail "test script contains a real APPLY=1 make memory-store-approved execution line"
fi
pass "test script does not execute APPLY=1"

mkdir -p "$test_tmp_dir/reports/memory-store"
cat > "$test_tmp_dir/reports/memory-store/memory-store-plan.json" <<'JSON'
{
  "human_review_required": true,
  "approved_candidates": [
    {
      "id": "memory-candidate-guardrail-001",
      "category": "workflow",
      "title": "Guard real apply",
      "proposed_memory_text": "Run read-only guardrails before manual memory apply."
    }
  ]
}
JSON
cat > "$test_tmp_dir/reports/memory-store/approved-memory-candidates.json" <<'JSON'
{
  "approved_candidate_ids": ["memory-candidate-guardrail-001"]
}
JSON

RUNTIME_DIR="$test_tmp_dir" "$SCRIPT" >"$test_tmp_dir/guardrail-pass.out"
pass "guardrail passes against isolated temporary runtime fixture"

cat > "$test_tmp_dir/reports/memory-store/approved-memory-candidates.json" <<'JSON'
{
  "test_fixture": true,
  "approved_candidate_ids": ["memory-candidate-guardrail-001"]
}
JSON

if RUNTIME_DIR="$test_tmp_dir" "$SCRIPT" >"$test_tmp_dir/guardrail-fail.out" 2>&1; then
  fail "guardrail should reject test_fixture=true approval files"
fi
pass "guardrail rejects test_fixture=true approval files"

if find "$ROOT" \( -name "memory-store-real-apply-guardrail-report.json" -o -name "memory-store-real-apply-guardrail.out" \) -print -quit | grep -q .; then
  fail "guardrail generated output was written inside the repository"
fi
pass "no generated guardrail output was written into the repo"

echo "Memory store real apply guardrail tests passed"
