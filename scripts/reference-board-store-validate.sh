#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-validate-report.json}"

export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID REPORT_PATH

python3 - <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


BOARD_ID_MAX_LENGTH = 80
SELECTED_REASON_MAX_LENGTH = 1000
TAG_MAX_COUNT = 12
TAG_MAX_LENGTH = 40
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")
TAG_PATTERN = re.compile(r"^[A-Za-z0-9 _-]+$")
HOST_PATH_MARKERS = ("/home/cuneyt", "/mnt", "/media")
KNOWN_ASSET_TYPES = {"image", "drawing_svg"}


runtime_dir = Path(os.environ["REFERENCE_BOARD_RUNTIME_DIR"])
board_id = os.environ["BOARD_ID"].strip()
report_path = Path(os.environ["REPORT_PATH"])
created_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

findings: list[dict[str, str]] = []
checked_count = 0
valid_count = 0
invalid_boards: set[str] = set()


def add_finding(target_board_id: str | None, file_path: Path | None, severity: str, code: str, detail: str) -> None:
    label = target_board_id or "unknown"
    findings.append(
        {
            "board_id": label,
            "file": str(file_path) if file_path is not None else "",
            "severity": severity,
            "code": code,
            "detail": detail,
        }
    )
    if severity == "error":
        invalid_boards.add(label)


def write_report(exit_code: int) -> None:
    report = {
        "schema_version": "1.0",
        "report_type": "reference_board_store_validation",
        "created_at": created_at,
        "runtime_dir": str(runtime_dir),
        "board_id": board_id or None,
        "checked_count": checked_count,
        "valid_count": valid_count,
        "invalid_count": len(invalid_boards),
        "findings": findings,
        "safety_flags": {
            "read_only": True,
            "source_assets_modified": False,
            "board_files_modified": False,
            "repair_applied": False,
            "backup_created": False,
            "generation_triggered": False,
        },
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    sys.exit(exit_code)


def is_safe_board_id(value: str) -> bool:
    if not value or len(value) > BOARD_ID_MAX_LENGTH:
        return False
    if "/" in value or "\\" in value or ".." in value or value.startswith("."):
        return False
    return BOARD_ID_PATTERN.fullmatch(value) is not None


def has_host_path(value: str) -> bool:
    if value.startswith(("~", "/")):
        return True
    return any(marker in value for marker in HOST_PATH_MARKERS)


def check_string(
    data: dict[str, Any],
    field: str,
    target_board_id: str,
    file_path: Path,
    *,
    required: bool = True,
) -> str | None:
    value = data.get(field)
    if value is None:
        if required:
            add_finding(target_board_id, file_path, "error", f"missing_{field}", f"{field} is required")
        return None
    if not isinstance(value, str):
        add_finding(target_board_id, file_path, "error", f"invalid_{field}", f"{field} must be a string")
        return None
    if field not in {"description", "selected_reason"} and not value:
        add_finding(target_board_id, file_path, "error", f"empty_{field}", f"{field} must not be empty")
    if has_host_path(value):
        add_finding(target_board_id, file_path, "error", f"host_path_{field}", f"{field} contains an unsafe host path")
    return value


def check_tags(value: Any, target_board_id: str, file_path: Path, item_label: str) -> None:
    if not isinstance(value, list):
        add_finding(target_board_id, file_path, "error", "invalid_tags", f"{item_label}.tags must be a list")
        return
    if len(value) > TAG_MAX_COUNT:
        add_finding(target_board_id, file_path, "error", "too_many_tags", f"{item_label}.tags exceeds tag count limit")
    for tag_index, tag in enumerate(value):
        tag_label = f"{item_label}.tags[{tag_index}]"
        if not isinstance(tag, str):
            add_finding(target_board_id, file_path, "error", "invalid_tag", f"{tag_label} must be a string")
            continue
        if not tag or len(tag) > TAG_MAX_LENGTH or TAG_PATTERN.fullmatch(tag) is None:
            add_finding(target_board_id, file_path, "error", "invalid_tag", f"{tag_label} is outside tag limits")
        if has_host_path(tag):
            add_finding(target_board_id, file_path, "error", "host_path_tag", f"{tag_label} contains an unsafe host path")


def validate_item(
    item: Any,
    index: int,
    target_board_id: str,
    file_path: Path,
    seen_item_ids: set[str],
    seen_card_ids: set[str],
) -> None:
    item_label = f"items[{index}]"
    if not isinstance(item, dict):
        add_finding(target_board_id, file_path, "error", "invalid_item", f"{item_label} must be an object")
        return

    stale_marker_valid = (
        item.get("stale") is True
        and isinstance(item.get("stale_reason"), str)
        and bool(item.get("stale_reason"))
        and isinstance(item.get("stale_checked_at"), str)
        and bool(item.get("stale_checked_at"))
    )

    item_id = check_string(item, "item_id", target_board_id, file_path)
    card_id = check_string(item, "card_id", target_board_id, file_path)
    asset_type = check_string(item, "asset_type", target_board_id, file_path)
    check_string(item, "name", target_board_id, file_path)
    if stale_marker_valid:
        raw_relative_runtime_path = item.get("relative_runtime_path")
        if raw_relative_runtime_path is None:
            add_finding(
                target_board_id,
                file_path,
                "warning",
                "stale_missing_relative_runtime_path",
                f"{item_label}.relative_runtime_path is missing on a marked stale item",
            )
            relative_runtime_path = None
        elif not isinstance(raw_relative_runtime_path, str):
            add_finding(
                target_board_id,
                file_path,
                "warning",
                "stale_invalid_relative_runtime_path",
                f"{item_label}.relative_runtime_path is not a string on a marked stale item",
            )
            relative_runtime_path = None
        elif not raw_relative_runtime_path:
            add_finding(
                target_board_id,
                file_path,
                "warning",
                "stale_empty_relative_runtime_path",
                f"{item_label}.relative_runtime_path is empty on a marked stale item",
            )
            relative_runtime_path = None
        else:
            relative_runtime_path = raw_relative_runtime_path
            if has_host_path(relative_runtime_path):
                add_finding(
                    target_board_id,
                    file_path,
                    "warning",
                    "stale_host_path_relative_runtime_path",
                    f"{item_label}.relative_runtime_path contains an unsafe host path on a marked stale item",
                )
    else:
        relative_runtime_path = check_string(item, "relative_runtime_path", target_board_id, file_path)
    selected_reason = check_string(item, "selected_reason", target_board_id, file_path)
    check_string(item, "safety_label", target_board_id, file_path)
    check_string(item, "added_at", target_board_id, file_path)

    if item_id:
        if item_id in seen_item_ids:
            add_finding(target_board_id, file_path, "error", "duplicate_item_id", f"duplicate item_id: {item_id}")
        seen_item_ids.add(item_id)
    if card_id:
        if card_id in seen_card_ids:
            add_finding(target_board_id, file_path, "error", "duplicate_card_id", f"duplicate card_id: {card_id}")
        seen_card_ids.add(card_id)
    if asset_type and asset_type not in KNOWN_ASSET_TYPES:
        add_finding(target_board_id, file_path, "warning", "unknown_asset_type", f"unknown asset_type: {asset_type}")
    if relative_runtime_path:
        parts = Path(relative_runtime_path).parts
        severity = "warning" if stale_marker_valid else "error"
        if Path(relative_runtime_path).is_absolute() or relative_runtime_path.startswith(("~", "/")):
            add_finding(target_board_id, file_path, severity, "absolute_relative_runtime_path", "relative_runtime_path must not be absolute")
        if ".." in parts:
            add_finding(target_board_id, file_path, severity, "traversal_relative_runtime_path", "relative_runtime_path must not contain traversal")
    if selected_reason and len(selected_reason) > SELECTED_REASON_MAX_LENGTH:
        add_finding(target_board_id, file_path, "error", "selected_reason_too_long", "selected_reason exceeds limit")
    check_tags(item.get("tags"), target_board_id, file_path, item_label)


def validate_board_file(file_path: Path) -> None:
    global checked_count, valid_count

    checked_count += 1
    target_board_id = file_path.stem
    before = len(findings)

    try:
        data = json.loads(file_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        add_finding(target_board_id, file_path, "error", "json_malformed", "board JSON does not parse")
        return
    except OSError:
        add_finding(target_board_id, file_path, "error", "board_file_unreadable", "board file cannot be read")
        return

    if not isinstance(data, dict):
        add_finding(target_board_id, file_path, "error", "top_level_not_object", "top-level JSON must be an object")
        return

    check_string(data, "schema_version", target_board_id, file_path)
    actual_board_id = check_string(data, "board_id", target_board_id, file_path)
    if actual_board_id:
        if not is_safe_board_id(actual_board_id):
            add_finding(target_board_id, file_path, "error", "invalid_board_id", "board_id does not match safe board id policy")
        if actual_board_id != file_path.stem:
            add_finding(target_board_id, file_path, "error", "board_id_filename_mismatch", "board_id does not match filename")
    check_string(data, "title", target_board_id, file_path)
    check_string(data, "description", target_board_id, file_path, required=False)
    check_string(data, "created_at", target_board_id, file_path)
    check_string(data, "updated_at", target_board_id, file_path)
    check_string(data, "safety_label", target_board_id, file_path)

    items = data.get("items")
    if not isinstance(items, list):
        add_finding(target_board_id, file_path, "error", "items_not_list", "items must be a list")
        return

    seen_item_ids: set[str] = set()
    seen_card_ids: set[str] = set()
    for index, item in enumerate(items):
        validate_item(item, index, target_board_id, file_path, seen_item_ids, seen_card_ids)

    if len(findings) == before:
        valid_count += 1


if board_id and not is_safe_board_id(board_id):
    add_finding(board_id, None, "error", "invalid_cli_board_id", "BOARD_ID does not match safe board id policy")
    print("Reference board store validation found issues")
    write_report(2)

if not runtime_dir.is_dir():
    add_finding(board_id or None, None, "error", "runtime_dir_missing", "reference board runtime directory is unavailable")
    print("Reference board store validation found issues")
    write_report(2)

if board_id:
    board_file = runtime_dir / f"{board_id}.json"
    if not board_file.is_file():
        checked_count = 1
        add_finding(board_id, board_file, "error", "board_file_missing", "board file does not exist")
    else:
        validate_board_file(board_file)
else:
    for board_file in sorted(runtime_dir.glob("*.json")):
        if board_file.is_file() and is_safe_board_id(board_file.stem):
            validate_board_file(board_file)

if findings:
    print("Reference board store validation found issues")
    write_report(1)

print("Reference board store validation OK")
write_report(0)
PY
