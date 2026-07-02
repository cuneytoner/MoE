#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_CANDIDATES_PATH="${RUNTIME_DIR}/reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_DIR="${RUNTIME_DIR}/reports/memory-store"
MEMORY_STORE_PLAN_PATH="${MEMORY_STORE_DIR}/memory-store-plan.json"
MEMORY_STORE_AUDIT_PATH="${MEMORY_STORE_DIR}/memory-store-audit.json"
HELPER_REPORT_PATH="${MEMORY_STORE_DIR}/memory-candidate-approval-helper-report.json"
EXAMPLE_APPROVAL_FILE_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.example.json"
APPROVAL_FILE_PATH="${MEMORY_STORE_DIR}/approved-memory-candidates.json"
APPLY_LOG_PATH="${MEMORY_STORE_DIR}/memory-store-apply-log.jsonl"
APPLY_SUMMARY_PATH="${MEMORY_STORE_DIR}/memory-store-apply-summary.json"
E2E_REPORT_PATH="${MEMORY_STORE_DIR}/memory-approval-dry-run-e2e-report.json"
USE_TEST_APPROVAL_FIXTURE="${USE_TEST_APPROVAL_FIXTURE:-0}"
KEEP_TEST_APPROVAL_FIXTURE="${KEEP_TEST_APPROVAL_FIXTURE:-0}"

export PYTHONDONTWRITEBYTECODE=1

if [ "${APPLY:-0}" = "1" ]; then
  echo "FAIL: APPLY=1 is not allowed for memory approval dry-run E2E." >&2
  exit 1
fi

mkdir -p "$MEMORY_STORE_DIR"
tmp_dir="$(mktemp -d /tmp/moe-memory-approval-e2e.XXXXXX)"
steps_jsonl="${tmp_dir}/steps.jsonl"
fixture_created=0
fixture_removed=0

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

add_step() {
  local name="$1"
  local status="$2"
  local command="$3"
  local summary="$4"
  local output_path="${5:-}"

  python3 - "$steps_jsonl" "$name" "$status" "$command" "$summary" "$output_path" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
entry = {
    "name": sys.argv[2],
    "status": sys.argv[3],
    "command": sys.argv[4],
    "summary": sys.argv[5],
}
if sys.argv[6]:
    entry["output_path"] = sys.argv[6]
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(entry, sort_keys=True) + "\n")
PY
}

run_step() {
  local name="$1"
  local command="$2"
  local output_path="${3:-}"
  local output_file="${tmp_dir}/${name//[^A-Za-z0-9_]/_}.out"
  local status="passed"
  local summary

  set +e
  bash -lc "$command" > "$output_file" 2>&1
  local rc=$?
  set -e

  sed -n '1,80p' "$output_file"
  if [ "$rc" -ne 0 ]; then
    status="failed"
  fi
  summary="$(tail -n 5 "$output_file" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c 1-280)"
  add_step "$name" "$status" "$command" "$summary" "$output_path"
  if [ "$rc" -ne 0 ]; then
    return "$rc"
  fi
}

json_value() {
  local path="$1"
  local filter="$2"
  if [ ! -f "$path" ]; then
    echo "0"
    return 0
  fi
  jq -r "$filter // 0" "$path" 2>/dev/null || echo "0"
}

approved_count_before="$(json_value "$MEMORY_STORE_PLAN_PATH" '.approved_candidates | length')"

run_step \
  "approval-helper" \
  "make -C '$ROOT' memory-candidate-approval-helper-local" \
  "$HELPER_REPORT_PATH"

run_step \
  "candidate-list" \
  "make -C '$ROOT' memory-candidate-list-local" \
  "$HELPER_REPORT_PATH"

if [ "$USE_TEST_APPROVAL_FIXTURE" = "1" ]; then
  if [ -f "$APPROVAL_FILE_PATH" ]; then
    existing_is_fixture="$(jq -r '.test_fixture // false' "$APPROVAL_FILE_PATH" 2>/dev/null || echo "false")"
    if [ "$existing_is_fixture" != "true" ]; then
      add_step \
        "test-approval-fixture" \
        "failed" \
        "USE_TEST_APPROVAL_FIXTURE=1" \
        "Refused to overwrite existing non-test approval file." \
        "$APPROVAL_FILE_PATH"
      echo "FAIL: Existing approval file is not a test fixture: $APPROVAL_FILE_PATH" >&2
      python3 - "$E2E_REPORT_PATH" "$steps_jsonl" "$approved_count_before" "0" "0" "0" "0" "0" "true" "false" <<'PY'
import json
import pathlib
import sys
from datetime import UTC, datetime

report_path = pathlib.Path(sys.argv[1])
steps = [json.loads(line) for line in pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if line.strip()]
report = {
    "generated_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
    "service": "memory-approval-dry-run-e2e",
    "e2e_status": "failed",
    "dry_run_only": True,
    "apply_used": False,
    "memory_write_supported": False,
    "human_review_required": True,
    "test_approval_fixture_used": True,
    "test_approval_fixture_removed": False,
    "input_paths": {},
    "output_paths": {},
    "step_results": steps,
    "approved_count_before": int(sys.argv[3]),
    "approved_count_after": 0,
    "dry_run_attempt_count": 0,
    "stored_count": 0,
    "failed_count": 0,
    "skipped_count": 0,
    "safety_boundaries": [],
    "validation_plan": [],
    "next_steps": ["Remove or review the existing approval file before using a test fixture."],
}
report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
      exit 1
    fi
  fi

  candidate_id="$(
    jq -r '
      .recommended_review_order
      | map(select((.duplicate_group_id == null) and (.risk == "low") and (.category == "workflow")))
      | (map(select(.candidate_id == "memory-candidate-001")) + .)
      | .[0].candidate_id // empty
    ' "$HELPER_REPORT_PATH" 2>/dev/null || true
  )"
  if [ -z "$candidate_id" ]; then
    candidate_id="$(
      jq -r '.candidate_cards | map(select(.risk == "low" and (.duplicate_group_id == null))) | .[0].id // empty' \
        "$HELPER_REPORT_PATH" 2>/dev/null || true
    )"
  fi
  if [ -z "$candidate_id" ]; then
    add_step "test-approval-fixture" "skipped" "USE_TEST_APPROVAL_FIXTURE=1" "No safe low-risk non-duplicate candidate was available." "$APPROVAL_FILE_PATH"
  else
    python3 - "$APPROVAL_FILE_PATH" "$candidate_id" <<'PY'
import json
import pathlib
import sys
from datetime import UTC, datetime

path = pathlib.Path(sys.argv[1])
candidate_id = sys.argv[2]
path.write_text(
    json.dumps(
        {
            "approved_candidate_ids": [candidate_id],
            "test_fixture": True,
            "dry_run_only": True,
            "created_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
            "notes": "Temporary dry-run E2E fixture; remove unless KEEP_TEST_APPROVAL_FIXTURE=1.",
        },
        indent=2,
        sort_keys=True,
    )
    + "\n",
    encoding="utf-8",
)
PY
    fixture_created=1
    add_step "test-approval-fixture" "passed" "USE_TEST_APPROVAL_FIXTURE=1" "Created temporary dry-run approval fixture for ${candidate_id}." "$APPROVAL_FILE_PATH"
  fi
else
  add_step "test-approval-fixture" "skipped" "USE_TEST_APPROVAL_FIXTURE=0" "No approval fixture requested." "$APPROVAL_FILE_PATH"
fi

run_step \
  "memory-store-plan" \
  "make -C '$ROOT' memory-store-plan-local" \
  "$MEMORY_STORE_PLAN_PATH"

approved_count_after="$(json_value "$MEMORY_STORE_PLAN_PATH" '.approved_candidates | length')"

run_step \
  "approved-store-dry-run" \
  "LOG_DRY_RUN=1 MEMORY_API_URL='http://127.0.0.1:1' make -C '$ROOT' memory-store-approved" \
  "$APPLY_SUMMARY_PATH"

run_step \
  "apply-log-status" \
  "make -C '$ROOT' memory-store-apply-log-status" \
  "$APPLY_SUMMARY_PATH"

run_step \
  "memory-store-audit" \
  "make -C '$ROOT' memory-store-audit-local" \
  "$MEMORY_STORE_AUDIT_PATH"

if [ "$fixture_created" = "1" ] && [ "$KEEP_TEST_APPROVAL_FIXTURE" != "1" ]; then
  rm -f "$APPROVAL_FILE_PATH"
  fixture_removed=1
  add_step "remove-test-approval-fixture" "passed" "rm approved-memory-candidates.json" "Removed temporary dry-run approval fixture." "$APPROVAL_FILE_PATH"
elif [ "$fixture_created" = "1" ]; then
  add_step "remove-test-approval-fixture" "warning" "KEEP_TEST_APPROVAL_FIXTURE=1" "Temporary dry-run approval fixture was kept by request." "$APPROVAL_FILE_PATH"
else
  add_step "remove-test-approval-fixture" "skipped" "fixture cleanup" "No test approval fixture was created." "$APPROVAL_FILE_PATH"
fi

dry_run_attempt_count="$(json_value "$APPLY_SUMMARY_PATH" '.dry_run_count')"
stored_count="$(json_value "$APPLY_SUMMARY_PATH" '.stored_count')"
failed_count="$(json_value "$APPLY_SUMMARY_PATH" '.failed_count')"
skipped_count="$(json_value "$APPLY_SUMMARY_PATH" '.skipped_count')"

python3 - "$E2E_REPORT_PATH" \
  "$steps_jsonl" \
  "$MEMORY_CANDIDATES_PATH" \
  "$MEMORY_STORE_PLAN_PATH" \
  "$MEMORY_STORE_AUDIT_PATH" \
  "$HELPER_REPORT_PATH" \
  "$EXAMPLE_APPROVAL_FILE_PATH" \
  "$APPROVAL_FILE_PATH" \
  "$APPLY_LOG_PATH" \
  "$APPLY_SUMMARY_PATH" \
  "$approved_count_before" \
  "$approved_count_after" \
  "$dry_run_attempt_count" \
  "$stored_count" \
  "$failed_count" \
  "$skipped_count" \
  "$USE_TEST_APPROVAL_FIXTURE" \
  "$fixture_removed" <<'PY'
import json
import pathlib
import sys
from datetime import UTC, datetime

(
    report_path,
    steps_path,
    candidates_path,
    plan_path,
    audit_path,
    helper_path,
    example_path,
    approval_path,
    apply_log_path,
    apply_summary_path,
    approved_before,
    approved_after,
    dry_run_attempt_count,
    stored_count,
    failed_count,
    skipped_count,
    fixture_used,
    fixture_removed,
) = sys.argv[1:]

steps = [
    json.loads(line)
    for line in pathlib.Path(steps_path).read_text(encoding="utf-8").splitlines()
    if line.strip()
]
statuses = {step.get("status") for step in steps}
if "failed" in statuses:
    e2e_status = "failed"
elif "warning" in statuses:
    e2e_status = "warning"
else:
    e2e_status = "passed"

report = {
    "generated_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
    "service": "memory-approval-dry-run-e2e",
    "e2e_status": e2e_status,
    "dry_run_only": True,
    "apply_used": False,
    "memory_write_supported": False,
    "human_review_required": True,
    "test_approval_fixture_used": fixture_used == "1",
    "test_approval_fixture_removed": fixture_removed == "1",
    "input_paths": {
        "feedback_memory_candidates": candidates_path,
        "memory_store_plan": plan_path,
        "memory_store_audit": audit_path,
        "approval_helper_report": helper_path,
        "example_approval_file": example_path,
        "approval_file": approval_path,
        "apply_log": apply_log_path,
        "apply_summary": apply_summary_path,
    },
    "output_paths": {
        "e2e_report": str(report_path),
        "memory_store_plan": plan_path,
        "memory_store_audit": audit_path,
        "approval_helper_report": helper_path,
        "apply_summary": apply_summary_path,
    },
    "step_results": steps,
    "approved_count_before": int(approved_before),
    "approved_count_after": int(approved_after),
    "dry_run_attempt_count": int(dry_run_attempt_count),
    "stored_count": int(stored_count),
    "failed_count": int(failed_count),
    "skipped_count": int(skipped_count),
    "safety_boundaries": [
        "no APPLY=1",
        "no real Memory API writes",
        "no automatic approval",
        "no permanent approval fixture unless explicitly kept",
        "no raw prompts",
        "no raw responses",
        "no individual feedback records",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no generated runtime report committed to repo",
    ],
    "validation_plan": [
        "make check-layout",
        "make check-python-syntax",
        "make memory-approval-dry-run-e2e-local",
        "USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local",
        "make test-memory-approval-dry-run-e2e",
        "make test-memory-candidate-approval-helper",
        "make test-memory-store-apply-log",
        "make test-memory-store-workflow",
        "make test",
    ],
    "next_steps": [
        "Review the E2E report and helper report.",
        "Create approved-memory-candidates.json manually only after human review.",
        "Regenerate the memory store plan after manual approval edits.",
        "Run make memory-store-approved without APPLY=1 before any real write.",
        "Use APPLY=1 only as a separate explicit human-run command.",
    ],
}
expanded = pathlib.Path(report_path)
expanded.parent.mkdir(parents=True, exist_ok=True)
expanded.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"PASS: Memory approval dry-run E2E report written to {expanded}")
print(f"  e2e_status: {e2e_status}")
print("  dry_run_only: true")
print("  apply_used: false")
print("  memory_write_supported: false")
print("  human_review_required: true")
print(f"  test_approval_fixture_used: {str(fixture_used == '1').lower()}")
print(f"  test_approval_fixture_removed: {str(fixture_removed == '1').lower()}")
print(f"  approved_count_before: {approved_before}")
print(f"  approved_count_after: {approved_after}")
print(f"  dry_run_attempt_count: {dry_run_attempt_count}")
print(f"  stored_count: {stored_count}")
print(f"  failed_count: {failed_count}")
print(f"  skipped_count: {skipped_count}")
PY
