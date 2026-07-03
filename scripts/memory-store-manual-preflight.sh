#!/usr/bin/env bash
set -euo pipefail

APPROVAL_FILE="/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json"
EXAMPLE_APPROVAL_FILE="/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json"
HELPER_REPORT="/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json"
STORE_PLAN="/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json"
STORE_AUDIT="/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json"
E2E_REPORT="/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json"
APPLY_SUMMARY="/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json"

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

exists_or_warn() {
  local path="$1"
  local label="$2"

  if [[ -f "$path" ]]; then
    pass "$label exists: $path"
  else
    warn "$label missing: $path"
  fi
}

valid_json_or_warn() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    warn "$label JSON not checked because file is missing"
    return 0
  fi

  if jq empty "$path" >/dev/null 2>&1; then
    pass "$label is valid JSON"
  else
    fail "$label is invalid JSON: $path"
  fi
}

json_value_or_warn() {
  local path="$1"
  local jq_expr="$2"
  local label="$3"

  if [[ ! -f "$path" ]]; then
    warn "$label unavailable because file is missing"
    return 0
  fi

  local value
  value="$(jq -r "$jq_expr // empty" "$path" 2>/dev/null || true)"

  if [[ -n "$value" && "$value" != "null" ]]; then
    pass "$label: $value"
  else
    warn "$label not found"
  fi
}

contains_forbidden_raw_fields() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    warn "$label raw-field scan skipped because file is missing"
    return 0
  fi

  if grep -Eq '"raw_prompt"|"raw_response"|"raw_model_response"|"raw_feedback_reason"' "$path"; then
    fail "$label contains forbidden raw prompt/response field names"
  else
    pass "$label contains no obvious raw prompt/response field names"
  fi
}

check_no_apply_environment() {
  if [[ "${APPLY:-}" == "1" ]]; then
    fail "APPLY=1 is present in environment; preflight must not run in apply mode"
  else
    pass "APPLY=1 is not set"
  fi
}


check_route_exists_in_source() {
  if grep -R "memory-approval/dashboard" apps packages docs README.md >/dev/null 2>&1; then
    pass "memory approval dashboard route is referenced in source/docs"
  else
    warn "memory approval dashboard route reference not found in source/docs"
  fi
}

check_approval_file_shape() {
  if [[ ! -f "$APPROVAL_FILE" ]]; then
    warn "real approval file is not present; this is expected until manual approval"
    return 0
  fi

  if jq -e '.approved_candidate_ids | type == "array"' "$APPROVAL_FILE" >/dev/null 2>&1; then
    pass "real approval file has approved_candidate_ids array"
  else
    fail "real approval file is missing approved_candidate_ids array"
  fi

  if jq -e '(.test_fixture // false) == true' "$APPROVAL_FILE" >/dev/null 2>&1; then
    warn "real approval file is marked test_fixture=true; do not use it for real APPLY=1"
  else
    pass "real approval file is not marked as a test fixture"
  fi

  local approved_count
  approved_count="$(jq -r '.approved_candidate_ids | length' "$APPROVAL_FILE" 2>/dev/null || echo 0)"
  pass "real approval file approved_candidate_ids count: $approved_count"
}

check_example_approval_shape() {
  if [[ ! -f "$EXAMPLE_APPROVAL_FILE" ]]; then
    warn "example approval file missing"
    return 0
  fi

  if jq -e '.approved_candidate_ids | type == "array"' "$EXAMPLE_APPROVAL_FILE" >/dev/null 2>&1; then
    pass "example approval file has approved_candidate_ids array"
  else
    fail "example approval file is missing approved_candidate_ids array"
  fi
}

check_duplicate_summary() {
  if [[ ! -f "$STORE_AUDIT" ]]; then
    warn "duplicate group check skipped because memory-store-audit.json is missing"
    return 0
  fi

  local duplicate_group_count
  duplicate_group_count="$(jq -r '.counts.duplicate_group_count // .duplicate_summary.duplicate_group_count // 0' "$STORE_AUDIT" 2>/dev/null || echo 0)"

  if [[ "$duplicate_group_count" =~ ^[0-9]+$ && "$duplicate_group_count" -gt 0 ]]; then
    warn "duplicate groups exist and must be reviewed before approval: $duplicate_group_count"
  else
    pass "no duplicate groups reported"
  fi
}

check_plan_counts() {
  if [[ ! -f "$STORE_PLAN" ]]; then
    warn "store plan counts unavailable because memory-store-plan.json is missing"
    return 0
  fi

  local approved_count blocked_count
  approved_count="$(jq -r '(.approved_candidates // []) | length' "$STORE_PLAN" 2>/dev/null || echo 0)"
  blocked_count="$(jq -r '(.blocked_candidates // []) | length' "$STORE_PLAN" 2>/dev/null || echo 0)"

  pass "store plan approved candidates: $approved_count"
  pass "store plan blocked candidates: $blocked_count"

  local memory_write_supported apply_supported human_review_required
  memory_write_supported="$(jq -r '.memory_write_supported // empty' "$STORE_PLAN" 2>/dev/null || true)"
  apply_supported="$(jq -r '.apply_supported // empty' "$STORE_PLAN" 2>/dev/null || true)"
  human_review_required="$(jq -r '.human_review_required // empty' "$STORE_PLAN" 2>/dev/null || true)"

  [[ "$memory_write_supported" == "false" ]] && pass "store plan memory_write_supported=false" || warn "store plan memory_write_supported is not false"
  [[ "$apply_supported" == "false" ]] && pass "store plan apply_supported=false" || warn "store plan apply_supported is not false"
  [[ "$human_review_required" == "true" ]] && pass "store plan human_review_required=true" || warn "store plan human_review_required is not true"
}

check_apply_summary_counts() {
  if [[ ! -f "$APPLY_SUMMARY" ]]; then
    warn "apply summary counts unavailable because memory-store-apply-summary.json is missing"
    return 0
  fi

  json_value_or_warn "$APPLY_SUMMARY" '.stored_count' "apply summary stored_count"
  json_value_or_warn "$APPLY_SUMMARY" '.dry_run_count' "apply summary dry_run_count"
  json_value_or_warn "$APPLY_SUMMARY" '.failed_count' "apply summary failed_count"
  json_value_or_warn "$APPLY_SUMMARY" '.skipped_count' "apply summary skipped_count"

  local raw_prompt raw_response
  raw_prompt="$(jq -r '.raw_prompt_included // empty' "$APPLY_SUMMARY" 2>/dev/null || true)"
  raw_response="$(jq -r '.raw_response_included // empty' "$APPLY_SUMMARY" 2>/dev/null || true)"

  [[ "$raw_prompt" == "false" ]] && pass "apply summary raw_prompt_included=false" || warn "apply summary raw_prompt_included not found or not false"
  [[ "$raw_response" == "false" ]] && pass "apply summary raw_response_included=false" || warn "apply summary raw_response_included not found or not false"
}

check_e2e_safety() {
  if [[ ! -f "$E2E_REPORT" ]]; then
    warn "E2E report safety check skipped because report is missing"
    return 0
  fi

  local dry_run_only apply_used memory_write_supported
  dry_run_only="$(jq -r '.dry_run_only // empty' "$E2E_REPORT" 2>/dev/null || true)"
  apply_used="$(jq -r '.apply_used // empty' "$E2E_REPORT" 2>/dev/null || true)"
  memory_write_supported="$(jq -r '.memory_write_supported // empty' "$E2E_REPORT" 2>/dev/null || true)"

  [[ "$dry_run_only" == "true" ]] && pass "E2E dry_run_only=true" || warn "E2E dry_run_only is not true"
  [[ "$apply_used" == "false" ]] && pass "E2E apply_used=false" || warn "E2E apply_used is not false"
  [[ "$memory_write_supported" == "false" ]] && pass "E2E memory_write_supported=false" || warn "E2E memory_write_supported is not false"
}

check_live_gateway_optional() {
  if [[ "${CHECK_LIVE_GATEWAY:-}" != "1" ]]; then
    warn "live Gateway check skipped; set CHECK_LIVE_GATEWAY=1 to enable"
    return 0
  fi

  local response
  response="$(curl -fsS http://localhost:8100/gateway/memory-approval/dashboard 2>/dev/null || true)"

  if [[ -z "$response" ]]; then
    warn "live Gateway check failed or endpoint unreachable"
    return 0
  fi

  local service read_only memory_write_supported
  service="$(printf '%s' "$response" | jq -r '.service // empty' 2>/dev/null || true)"
  read_only="$(printf '%s' "$response" | jq -r '.read_only // empty' 2>/dev/null || true)"
  memory_write_supported="$(printf '%s' "$response" | jq -r '.memory_write_supported // empty' 2>/dev/null || true)"

  if [[ "$service" == "memory-approval-dashboard" && "$read_only" == "true" && "$memory_write_supported" == "false" ]]; then
    pass "live Gateway memory approval dashboard endpoint is safe"
  else
    warn "live Gateway endpoint returned unexpected contract"
  fi
}

echo "Memory store manual preflight"
echo "  mode: read-only"
echo "  apply_env: ${APPLY:-unset}"
echo

check_no_apply_environment

exists_or_warn "$EXAMPLE_APPROVAL_FILE" "example approval file"
exists_or_warn "$APPROVAL_FILE" "real approval file"
exists_or_warn "$HELPER_REPORT" "approval helper report"
exists_or_warn "$STORE_PLAN" "memory store plan"
exists_or_warn "$STORE_AUDIT" "memory store audit"
exists_or_warn "$E2E_REPORT" "memory approval dry-run E2E report"
exists_or_warn "$APPLY_SUMMARY" "memory store apply summary"

valid_json_or_warn "$EXAMPLE_APPROVAL_FILE" "example approval file"
valid_json_or_warn "$APPROVAL_FILE" "real approval file"
valid_json_or_warn "$HELPER_REPORT" "approval helper report"
valid_json_or_warn "$STORE_PLAN" "memory store plan"
valid_json_or_warn "$STORE_AUDIT" "memory store audit"
valid_json_or_warn "$E2E_REPORT" "memory approval dry-run E2E report"
valid_json_or_warn "$APPLY_SUMMARY" "memory store apply summary"

check_example_approval_shape
check_approval_file_shape
check_route_exists_in_source
check_duplicate_summary
check_plan_counts
check_apply_summary_counts
check_e2e_safety
contains_forbidden_raw_fields "$HELPER_REPORT" "approval helper report"
contains_forbidden_raw_fields "$STORE_PLAN" "memory store plan"
check_live_gateway_optional

echo
echo "Preflight summary"
echo "  PASS: $PASS_COUNT"
echo "  WARN: $WARN_COUNT"
echo "  FAIL: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi

exit 0
