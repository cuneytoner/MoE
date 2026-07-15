#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-repair-regression-board}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-repair-report.json}"
BACKUP_DIR="${REFERENCE_BOARD_RUNTIME_DIR}/backups"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_FILE="${REFERENCE_BOARD_RUNTIME_DIR}/${BOARD_ID}.json"
export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID BACKUP_DIR REPORT_PATH BOARD_FILE

fail() {
  echo "Reference board store repair regression FAIL: $*" >&2
  exit 1
}

cleanup() {
  rm -f "$BOARD_FILE"
  rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak
}
trap cleanup EXIT

assert_report_no_action_path_leak() {
  local report="$1"
  jq -e '
    [
      .findings[]?.detail,
      .proposed_actions[]?.detail,
      .applied_actions[]?.detail,
      .skipped_actions[]?.detail
    ]
    | map(select(type == "string"))
    | all((contains("/home/cuneyt") or contains("/mnt") or contains("/media")) | not)
  ' "$report" >/dev/null
}

if [ "$BOARD_ID" != "repair-regression-board" ]; then
  fail "BOARD_ID must remain repair-regression-board for this controlled regression"
fi

if [ ! -d "$REFERENCE_BOARD_RUNTIME_DIR" ]; then
  fail "reference board runtime dir does not exist"
fi

if [ -e "$BOARD_FILE" ]; then
  fail "refusing to overwrite existing regression board file"
fi

cleanup

python3 - <<'PY'
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

board_file = Path(os.environ["BOARD_FILE"])
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
fixture = {
    "schema_version": "1.0",
    "board_id": os.environ["BOARD_ID"],
    "title": "  Repair Regression Board  ",
    "description": "  Temporary repair regression fixture  ",
    "created_at": now,
    "updated_at": now,
    "items": [
        {
            "item_id": "repair_regression_item_one",
            "card_id": "image:repair-regression-one.png",
            "asset_type": "image",
            "name": "repair-regression-one.png",
            "relative_runtime_path": "repair-regression/one.png",
            "selected_reason": "  needs trimming  ",
            "tags": [" keep ", "", "keep", "second"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "repair_regression_item_two",
            "card_id": "drawing_svg:repair-regression/two.svg",
            "asset_type": "drawing_svg",
            "name": "repair-regression-two.svg",
            "relative_runtime_path": "repair-regression/two.svg",
            "safety_label": "test_fixture",
            "added_at": now,
        },
    ],
}
board_file.write_text(json.dumps(fixture, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

dry_run_status=0
BOARD_ID="$BOARD_ID" REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || dry_run_status=$?
if [ "$dry_run_status" != "0" ] && [ "$dry_run_status" != "1" ]; then
  fail "dry-run returned unexpected status $dry_run_status"
fi
jq -e '.report_type == "reference_board_store_repair"' "$REPORT_PATH" >/dev/null
jq -e '.apply == false' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
jq -e '(.proposed_actions | length) > 0' "$REPORT_PATH" >/dev/null
assert_report_no_action_path_leak "$REPORT_PATH"

grep -F '"title": "  Repair Regression Board  "' "$BOARD_FILE" >/dev/null || fail "dry-run modified title"
grep -F '"description": "  Temporary repair regression fixture  "' "$BOARD_FILE" >/dev/null || fail "dry-run modified description"
grep -F '"selected_reason": "  needs trimming  "' "$BOARD_FILE" >/dev/null || fail "dry-run modified selected_reason"
grep -F '"tags": [' "$BOARD_FILE" >/dev/null || fail "dry-run changed tags shape unexpectedly"

rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak

apply_without_backup_status=0
BOARD_ID="$BOARD_ID" APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || apply_without_backup_status=$?
if [ "$apply_without_backup_status" = "0" ]; then
  fail "APPLY=1 without backup unexpectedly succeeded"
fi
jq -e '.findings[]? | select(.code == "backup_required_missing")' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
grep -F '"title": "  Repair Regression Board  "' "$BOARD_FILE" >/dev/null || fail "failed apply modified title"

BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-backup.sh" >/dev/null
backup_count="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "reference-board-${BOARD_ID}-*.json.bak" | wc -l)"
if [ "$backup_count" -lt 1 ]; then
  fail "backup was not created"
fi

BOARD_ID="$BOARD_ID" APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" >/dev/null
jq -e '.safety_flags.board_file_modified == true' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.repair_applied == true' "$REPORT_PATH" >/dev/null
jq -e '(.applied_actions | length) > 0' "$REPORT_PATH" >/dev/null
assert_report_no_action_path_leak "$REPORT_PATH"

BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-validate.sh" >/dev/null
jq -e '.report_type == "reference_board_store_validation"' /tmp/moe-reference-board-store-validate-report.json >/dev/null
jq -e '(.findings | length) == 0' /tmp/moe-reference-board-store-validate-report.json >/dev/null

echo "Reference board store repair regression OK"
