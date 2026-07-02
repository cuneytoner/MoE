#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
E2E_REPORT_PATH="${RUNTIME_DIR}/reports/memory-store/memory-approval-dry-run-e2e-report.json"

if [ ! -f "$E2E_REPORT_PATH" ]; then
  echo "SKIP: Memory approval dry-run E2E report is missing: $E2E_REPORT_PATH"
  echo "Run make memory-approval-dry-run-e2e-local first."
  exit 0
fi

jq -r '
  def bool_value(key; fallback):
    if has(key) then .[key] else fallback end | tostring;
  "Memory approval dry-run E2E status",
  "  report_path: " + "'"$E2E_REPORT_PATH"'",
  "  e2e_status: " + (.e2e_status // "unknown"),
  "  dry_run_only: " + bool_value("dry_run_only"; false),
  "  apply_used: " + bool_value("apply_used"; true),
  "  memory_write_supported: " + bool_value("memory_write_supported"; true),
  "  human_review_required: " + bool_value("human_review_required"; false),
  "  test_approval_fixture_used: " + bool_value("test_approval_fixture_used"; false),
  "  test_approval_fixture_removed: " + bool_value("test_approval_fixture_removed"; false),
  "  approved_count_before: " + ((.approved_count_before // 0) | tostring),
  "  approved_count_after: " + ((.approved_count_after // 0) | tostring),
  "  dry_run_attempt_count: " + ((.dry_run_attempt_count // 0) | tostring),
  "  stored_count: " + ((.stored_count // 0) | tostring),
  "  failed_count: " + ((.failed_count // 0) | tostring),
  "  skipped_count: " + ((.skipped_count // 0) | tostring)
' "$E2E_REPORT_PATH"
