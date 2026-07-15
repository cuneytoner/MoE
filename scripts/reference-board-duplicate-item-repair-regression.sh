#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-duplicate-repair-regression-board}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-repair-report.json}"
BACKUP_DIR="${REFERENCE_BOARD_RUNTIME_DIR}/backups"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_FILE="${REFERENCE_BOARD_RUNTIME_DIR}/${BOARD_ID}.json"
export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID BACKUP_DIR REPORT_PATH BOARD_FILE

fail() {
  echo "Reference board duplicate item repair regression FAIL: $*" >&2
  exit 1
}

cleanup() {
  rm -f "$BOARD_FILE"
  rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak
}
trap cleanup EXIT

assert_duplicates_present() {
  jq -e '
    ([.items[].item_id] | length) > ([.items[].item_id] | unique | length) and
    ([.items[].card_id] | length) > ([.items[].card_id] | unique | length) and
    ([.items[].relative_runtime_path] | length) > ([.items[].relative_runtime_path] | unique | length)
  ' "$BOARD_FILE" >/dev/null
}

if [ "$BOARD_ID" != "duplicate-repair-regression-board" ]; then
  fail "BOARD_ID must remain duplicate-repair-regression-board for this controlled regression"
fi

if [ ! -d "$REFERENCE_BOARD_RUNTIME_DIR" ]; then
  fail "reference board runtime dir does not exist"
fi

if [ -e "$BOARD_FILE" ]; then
  fail "refusing to overwrite existing duplicate repair regression board file"
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
    "title": "Duplicate Repair Regression Board",
    "description": "Temporary duplicate item repair regression fixture",
    "created_at": now,
    "updated_at": now,
    "safety_label": "visual_reference_only",
    "items": [
        {
            "item_id": "dup_item_id",
            "card_id": "image:duplicate-regression-a.png",
            "asset_type": "image",
            "name": "duplicate-regression-a.png",
            "relative_runtime_path": "duplicate-regression/a.png",
            "selected_reason": "preserved item_id occurrence",
            "tags": ["first", "item-id"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "dup_item_id",
            "card_id": "image:duplicate-regression-b.png",
            "asset_type": "image",
            "name": "duplicate-regression-b.png",
            "relative_runtime_path": "duplicate-regression/b.png",
            "selected_reason": "later duplicate item_id with different note",
            "tags": ["second", "item-id"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "dup_card_first",
            "card_id": "image:duplicate-regression-card.png",
            "asset_type": "image",
            "name": "duplicate-regression-card-first.png",
            "relative_runtime_path": "duplicate-regression/card-first.png",
            "selected_reason": "preserved card occurrence",
            "tags": ["first", "card"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "dup_card_second",
            "card_id": "image:duplicate-regression-card.png",
            "asset_type": "image",
            "name": "duplicate-regression-card-second.png",
            "relative_runtime_path": "duplicate-regression/card-second.png",
            "selected_reason": "later duplicate card with different tags",
            "tags": ["second", "card"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "dup_path_first",
            "card_id": "image:duplicate-regression-path-first.png",
            "asset_type": "image",
            "name": "duplicate-regression-path-first.png",
            "relative_runtime_path": "duplicate-regression/shared-path.png",
            "selected_reason": "preserved path occurrence",
            "tags": ["first", "path"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "dup_path_second",
            "card_id": "drawing_svg:duplicate-regression-path-second.svg",
            "asset_type": "drawing_svg",
            "name": "duplicate-regression-path-second.svg",
            "relative_runtime_path": "duplicate-regression/shared-path.png",
            "selected_reason": "later duplicate path with different asset type",
            "tags": ["second", "path"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
        {
            "item_id": "unique_item_must_remain",
            "card_id": "image:duplicate-regression-unique.png",
            "asset_type": "image",
            "name": "duplicate-regression-unique.png",
            "relative_runtime_path": "duplicate-regression/unique.png",
            "selected_reason": "unique item",
            "tags": ["unique"],
            "safety_label": "test_fixture",
            "added_at": now,
        },
    ],
}
board_file.write_text(json.dumps(fixture, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

dry_run_status=0
BOARD_ID="$BOARD_ID" MODE=remove-duplicate-items REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || dry_run_status=$?
if [ "$dry_run_status" != "0" ]; then
  fail "dry-run returned unexpected status $dry_run_status"
fi
jq -e '.report_type == "reference_board_store_repair"' "$REPORT_PATH" >/dev/null
jq -e '.mode == "remove-duplicate-items"' "$REPORT_PATH" >/dev/null
jq -e '.apply == false' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.repair_applied == false' "$REPORT_PATH" >/dev/null
jq -e '(.duplicate_groups | length) >= 3' "$REPORT_PATH" >/dev/null
jq -e '(.proposed_removals | length) >= 3' "$REPORT_PATH" >/dev/null
assert_duplicates_present

rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak

apply_without_backup_status=0
BOARD_ID="$BOARD_ID" MODE=remove-duplicate-items APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || apply_without_backup_status=$?
if [ "$apply_without_backup_status" = "0" ]; then
  fail "APPLY=1 without backup unexpectedly succeeded"
fi
jq -e '.findings[]? | select(.code == "backup_required_missing")' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
assert_duplicates_present

BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-backup.sh" >/dev/null
backup_count="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "reference-board-${BOARD_ID}-*.json.bak" | wc -l)"
if [ "$backup_count" -lt 1 ]; then
  fail "backup was not created"
fi

BOARD_ID="$BOARD_ID" MODE=remove-duplicate-items APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" >/dev/null
jq -e '.safety_flags.board_file_modified == true' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.repair_applied == true' "$REPORT_PATH" >/dev/null
jq -e '(.applied_removals | length) >= 3' "$REPORT_PATH" >/dev/null

jq -e '
  ([.items[].item_id] | length) == ([.items[].item_id] | unique | length) and
  ([.items[].card_id] | length) == ([.items[].card_id] | unique | length) and
  ([.items[].relative_runtime_path] | length) == ([.items[].relative_runtime_path] | unique | length)
' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "dup_item_id" and .card_id == "image:duplicate-regression-a.png")' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "dup_card_first")' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "dup_path_first")' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "unique_item_must_remain")' "$BOARD_FILE" >/dev/null
jq -e 'all(.items[]; .item_id != "dup_card_second" and .item_id != "dup_path_second")' "$BOARD_FILE" >/dev/null

BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-validate.sh" >/dev/null
jq -e '.report_type == "reference_board_store_validation"' /tmp/moe-reference-board-store-validate-report.json >/dev/null
jq -e '(.findings | length) == 0' /tmp/moe-reference-board-store-validate-report.json >/dev/null

echo "Reference board duplicate item repair regression OK"
