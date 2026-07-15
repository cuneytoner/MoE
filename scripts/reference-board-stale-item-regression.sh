#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-stale-item-regression-board}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-repair-report.json}"
BACKUP_DIR="${REFERENCE_BOARD_RUNTIME_DIR}/backups"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOARD_FILE="${REFERENCE_BOARD_RUNTIME_DIR}/${BOARD_ID}.json"
FAKE_ASSET_ONE="/home/cuneyt/MoE/runtime/media/outputs/images/stale-regression/missing-relative-path.png"
FAKE_ASSET_TWO="/home/cuneyt/MoE/runtime/media/outputs/images/stale-regression/missing-output-card.png"
FAKE_ASSET_THREE="/home/cuneyt/MoE/runtime/media/outputs/images/stale-regression/missing-metadata-asset.png"
export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID BACKUP_DIR REPORT_PATH BOARD_FILE

fail() {
  echo "Reference board stale item regression FAIL: $*" >&2
  exit 1
}

cleanup() {
  rm -f "$BOARD_FILE"
  rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak
}
trap cleanup EXIT

assert_no_stale_markers() {
  jq -e 'all(.items[]; ((has("stale") or has("stale_reason") or has("stale_checked_at")) | not))' "$BOARD_FILE" >/dev/null
}

assert_fake_assets_absent() {
  [ ! -e "$FAKE_ASSET_ONE" ] || fail "unexpected fake asset exists: $FAKE_ASSET_ONE"
  [ ! -e "$FAKE_ASSET_TWO" ] || fail "unexpected fake asset exists: $FAKE_ASSET_TWO"
  [ ! -e "$FAKE_ASSET_THREE" ] || fail "unexpected fake asset exists: $FAKE_ASSET_THREE"
}

if [ "$BOARD_ID" != "stale-item-regression-board" ]; then
  fail "BOARD_ID must remain stale-item-regression-board for this controlled regression"
fi

if [ ! -d "$REFERENCE_BOARD_RUNTIME_DIR" ]; then
  fail "reference board runtime dir does not exist"
fi

if [ -e "$BOARD_FILE" ]; then
  fail "refusing to overwrite existing stale item regression board file"
fi

assert_fake_assets_absent
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
    "title": "Stale Item Regression Board",
    "description": "Temporary stale item marking regression fixture",
    "created_at": now,
    "updated_at": now,
    "safety_label": "visual_reference_only",
    "items": [
        {
            "item_id": "stale_missing_relative_runtime_path",
            "card_id": "image:media/outputs/images/stale-regression/missing-relative-path.png",
            "asset_type": "image",
            "name": "missing-relative-path.png",
            "selected_reason": "stale because relative_runtime_path is missing",
            "tags": ["stale", "missing-path"],
            "safety_label": "visual_reference_only",
            "added_at": now,
        },
        {
            "item_id": "stale_absolute_relative_runtime_path",
            "card_id": "image:media/outputs/images/stale-regression/absolute-path.png",
            "asset_type": "image",
            "name": "absolute-path.png",
            "relative_runtime_path": "/home/cuneyt/MoE/runtime/media/outputs/images/stale-regression/absolute-path.png",
            "selected_reason": "stale because relative_runtime_path is absolute",
            "tags": ["stale", "absolute-path"],
            "safety_label": "visual_reference_only",
            "added_at": now,
        },
        {
            "item_id": "stale_traversal_relative_runtime_path",
            "card_id": "image:media/outputs/images/stale-regression/traversal-path.png",
            "asset_type": "image",
            "name": "traversal-path.png",
            "relative_runtime_path": "media/outputs/images/../stale-regression/traversal-path.png",
            "selected_reason": "stale because relative_runtime_path contains traversal",
            "tags": ["stale", "traversal-path"],
            "safety_label": "visual_reference_only",
            "added_at": now,
        },
        {
            "item_id": "stale_unsafe_metadata_path",
            "card_id": "image:media/outputs/images/stale-regression/missing-metadata-asset.png",
            "asset_type": "image",
            "name": "missing-metadata-asset.png",
            "relative_runtime_path": "media/outputs/images/stale-regression/missing-metadata-asset.png",
            "metadata_path": "/home/cuneyt/MoE/runtime/media/outputs/images/stale-regression/missing-metadata-asset.json",
            "selected_reason": "stale because metadata_path is absolute and unsafe",
            "tags": ["stale", "metadata"],
            "safety_label": "visual_reference_only",
            "added_at": now,
        },
        {
            "item_id": "non_stale_shape_control",
            "card_id": "image:media/outputs/images/stale-regression/non-stale-shape-control.png",
            "asset_type": "image",
            "name": "non-stale-shape-control.png",
            "relative_runtime_path": "media/outputs/images/stale-regression/non-stale-shape-control.png",
            "selected_reason": "shape-only control that stays structurally valid without asset creation",
            "tags": ["shape-control"],
            "safety_label": "visual_reference_only",
            "added_at": now,
        },
    ],
}
board_file.write_text(json.dumps(fixture, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

dry_run_status=0
BOARD_ID="$BOARD_ID" MODE=mark-stale-items REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || dry_run_status=$?
if [ "$dry_run_status" != "0" ]; then
  fail "dry-run returned unexpected status $dry_run_status"
fi
jq -e '.report_type == "reference_board_store_repair"' "$REPORT_PATH" >/dev/null
jq -e '.mode == "mark-stale-items"' "$REPORT_PATH" >/dev/null
jq -e '.apply == false' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.repair_applied == false' "$REPORT_PATH" >/dev/null
jq -e '(.stale_items | length) >= 4' "$REPORT_PATH" >/dev/null
jq -e '(.proposed_stale_marks | length) >= 4' "$REPORT_PATH" >/dev/null
assert_no_stale_markers
assert_fake_assets_absent

rm -f "$BACKUP_DIR"/reference-board-"$BOARD_ID"-*.json.bak

apply_without_backup_status=0
BOARD_ID="$BOARD_ID" MODE=mark-stale-items APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" || apply_without_backup_status=$?
if [ "$apply_without_backup_status" = "0" ]; then
  fail "APPLY=1 without backup unexpectedly succeeded"
fi
jq -e '.findings[]? | select(.code == "backup_required_missing")' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.board_file_modified == false' "$REPORT_PATH" >/dev/null
assert_no_stale_markers
assert_fake_assets_absent

BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-backup.sh" >/dev/null
backup_count="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "reference-board-${BOARD_ID}-*.json.bak" | wc -l)"
if [ "$backup_count" -lt 1 ]; then
  fail "backup was not created"
fi

BOARD_ID="$BOARD_ID" MODE=mark-stale-items APPLY=1 REPORT_PATH="$REPORT_PATH" "$SCRIPT_DIR/reference-board-store-repair.sh" >/dev/null
jq -e '.safety_flags.board_file_modified == true' "$REPORT_PATH" >/dev/null
jq -e '.safety_flags.repair_applied == true' "$REPORT_PATH" >/dev/null
jq -e '(.applied_stale_marks | length) >= 4' "$REPORT_PATH" >/dev/null

jq -e '(.items | length) == 5' "$BOARD_FILE" >/dev/null
jq -e '([.items[] | select(.stale == true and (.stale_reason | type == "string") and (.stale_checked_at | type == "string"))] | length) >= 4' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "stale_missing_relative_runtime_path" and .stale == true)' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "stale_absolute_relative_runtime_path" and .stale == true)' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "stale_traversal_relative_runtime_path" and .stale == true)' "$BOARD_FILE" >/dev/null
jq -e '.items[] | select(.item_id == "stale_unsafe_metadata_path" and .stale == true)' "$BOARD_FILE" >/dev/null
assert_fake_assets_absent

validate_status=0
BOARD_ID="$BOARD_ID" "$SCRIPT_DIR/reference-board-store-validate.sh" >/dev/null || validate_status=$?
if [ "$validate_status" != "0" ] && [ "$validate_status" != "1" ]; then
  fail "validate returned unexpected status $validate_status"
fi
jq -e '.report_type == "reference_board_store_validation"' /tmp/moe-reference-board-store-validate-report.json >/dev/null
jq -e '([.findings[]? | select(.severity == "error")] | length) == 0' /tmp/moe-reference-board-store-validate-report.json >/dev/null

echo "Reference board stale item regression OK"
