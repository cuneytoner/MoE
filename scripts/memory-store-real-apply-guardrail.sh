#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
APPROVAL_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
ALLOW_BATCH_MEMORY_APPLY="${ALLOW_BATCH_MEMORY_APPLY:-0}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $*"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo "WARN: $*"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL: $*"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

valid_json() {
  local path="$1"
  local label="$2"

  if jq empty "$path" >/dev/null 2>&1; then
    pass "$label is valid JSON"
  else
    fail "$label is invalid JSON: $path"
  fi
}

jq_value() {
  local path="$1"
  local expr="$2"
  jq -r "$expr" "$path" 2>/dev/null || true
}

check_forbidden_fields() {
  local path="$1"
  local label="$2"

  if grep -Eq '"(raw_prompt|raw_response|raw_model_response|raw_feedback_reason|prompt_text|response_text|feedback_records)"[[:space:]]*:' "$path"; then
    fail "$label contains forbidden raw prompt/response field markers"
  else
    pass "$label contains no forbidden raw prompt/response field markers"
  fi
}

echo "Memory store real apply guardrail"
echo "  mode: read-only"
echo "  memory_store_dir: $MEMORY_STORE_DIR"

if [[ "${APPLY:-0}" == "1" ]]; then
  warn "APPLY=1 is set in the environment; guardrail remains read-only and will not apply"
else
  pass "APPLY=1 is not set"
fi

if [[ -f "$PLAN_PATH" ]]; then
  pass "memory-store-plan.json exists: $PLAN_PATH"
else
  fail "memory-store-plan.json missing: $PLAN_PATH"
fi

if [[ -f "$APPROVAL_PATH" ]]; then
  pass "approved-memory-candidates.json exists: $APPROVAL_PATH"
else
  fail "approved-memory-candidates.json missing: $APPROVAL_PATH"
fi

if [[ -f "$PLAN_PATH" ]]; then
  valid_json "$PLAN_PATH" "memory-store-plan.json"
fi

if [[ -f "$APPROVAL_PATH" ]]; then
  valid_json "$APPROVAL_PATH" "approved-memory-candidates.json"
fi

if [[ -f "$APPROVAL_PATH" ]] && jq empty "$APPROVAL_PATH" >/dev/null 2>&1; then
  if jq -e '.approved_candidate_ids | type == "array"' "$APPROVAL_PATH" >/dev/null 2>&1; then
    pass "approved-memory-candidates.json has approved_candidate_ids array"
  else
    fail "approved-memory-candidates.json is missing approved_candidate_ids array"
  fi

  approved_id_count="$(jq_value "$APPROVAL_PATH" 'if (.approved_candidate_ids | type == "array") then (.approved_candidate_ids | length) else 0 end')"
  if [[ "$approved_id_count" =~ ^[0-9]+$ && "$approved_id_count" -gt 0 ]]; then
    pass "approved_candidate_ids count is greater than zero: $approved_id_count"
  else
    fail "approved_candidate_ids count must be greater than zero"
  fi

  if jq -e '(.test_fixture // false) == true' "$APPROVAL_PATH" >/dev/null 2>&1; then
    fail "approved-memory-candidates.json is marked test_fixture=true"
  else
    pass "approved-memory-candidates.json is not marked test_fixture=true"
  fi

  if jq -e '(.dry_run_only // false) == true' "$APPROVAL_PATH" >/dev/null 2>&1; then
    fail "approved-memory-candidates.json is marked dry_run_only=true"
  else
    pass "approved-memory-candidates.json is not marked dry_run_only=true"
  fi

  check_forbidden_fields "$APPROVAL_PATH" "approved-memory-candidates.json"
fi

if [[ -f "$PLAN_PATH" ]] && jq empty "$PLAN_PATH" >/dev/null 2>&1; then
  if jq -e '.approved_candidates | type == "array"' "$PLAN_PATH" >/dev/null 2>&1; then
    pass "memory-store-plan.json has approved_candidates list"
  else
    fail "memory-store-plan.json is missing approved_candidates list"
  fi

  approved_candidate_count="$(jq_value "$PLAN_PATH" 'if (.approved_candidates | type == "array") then (.approved_candidates | length) else 0 end')"
  if [[ "$approved_candidate_count" =~ ^[0-9]+$ && "$approved_candidate_count" -gt 0 ]]; then
    pass "approved_candidates count is greater than zero: $approved_candidate_count"
  else
    fail "approved_candidates count must be greater than zero"
  fi

  if jq -e '.human_review_required == true' "$PLAN_PATH" >/dev/null 2>&1; then
    pass "memory-store-plan.json has human_review_required=true"
  else
    fail "memory-store-plan.json must have human_review_required=true"
  fi

  check_forbidden_fields "$PLAN_PATH" "memory-store-plan.json"

  if [[ "$approved_candidate_count" =~ ^[0-9]+$ && "$approved_candidate_count" -gt 1 ]]; then
    if [[ "$ALLOW_BATCH_MEMORY_APPLY" == "1" ]]; then
      pass "batch apply warning acknowledged with ALLOW_BATCH_MEMORY_APPLY=1"
    else
      warn "approved_candidates count is greater than one; review batch carefully or set ALLOW_BATCH_MEMORY_APPLY=1 to silence this warning"
    fi
  fi
fi

echo ""
echo "Guardrail summary"
echo "  PASS: $PASS_COUNT"
echo "  WARN: $WARN_COUNT"
echo "  FAIL: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
