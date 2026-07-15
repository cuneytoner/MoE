#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-}"
MODE="${MODE:-repair-schema}"
APPLY="${APPLY:-0}"
REQUIRE_BACKUP="${REQUIRE_BACKUP:-1}"
BACKUP_DIR="${BACKUP_DIR:-${REFERENCE_BOARD_RUNTIME_DIR}/backups}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-repair-report.json}"

export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID MODE APPLY REQUIRE_BACKUP BACKUP_DIR REPORT_PATH

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
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")

runtime_dir = Path(os.environ["REFERENCE_BOARD_RUNTIME_DIR"])
runtime_root = Path(os.environ.get("RUNTIME_ROOT", "/home/cuneyt/MoE/runtime"))
board_id = os.environ["BOARD_ID"].strip()
mode = os.environ["MODE"].strip()
apply_requested = os.environ["APPLY"] == "1"
require_backup = os.environ["REQUIRE_BACKUP"] != "0"
backup_dir = Path(os.environ["BACKUP_DIR"])
report_path = Path(os.environ["REPORT_PATH"])
created_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

findings: list[dict[str, str]] = []
proposed_actions: list[dict[str, str]] = []
applied_actions: list[dict[str, str]] = []
skipped_actions: list[dict[str, str]] = []
board_file: Path | None = None
backup_found = False
board_file_modified = False
repair_applied = False
duplicate_groups: list[dict[str, Any]] = []
proposed_removals: list[dict[str, Any]] = []
applied_removals: list[dict[str, Any]] = []
skipped_removals: list[dict[str, Any]] = []
stale_checked_at = created_at
stale_check_limited = False
stale_items: list[dict[str, Any]] = []
proposed_stale_marks: list[dict[str, Any]] = []
applied_stale_marks: list[dict[str, Any]] = []
skipped_stale_marks: list[dict[str, Any]] = []

ALLOWLISTED_RUNTIME_ROOTS = (
    runtime_root / "media" / "outputs" / "images",
    runtime_root / "pergola" / "drawings",
    runtime_root / "drawings",
)
SUPPORTED_OUTPUT_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".svg"}


def add_finding(severity: str, code: str, detail: str) -> None:
    findings.append({"severity": severity, "code": code, "detail": detail})


def add_action(target: list[dict[str, str]], code: str, detail: str) -> None:
    target.append({"code": code, "detail": detail})


def write_report(exit_code: int) -> None:
    report = {
        "schema_version": "1.0",
        "report_type": "reference_board_store_repair",
        "created_at": created_at,
        "runtime_dir": str(runtime_dir),
        "board_id": board_id or None,
        "mode": mode,
        "apply": apply_requested,
        "backup_required": require_backup,
        "backup_found": backup_found,
        "board_file": str(board_file) if board_file is not None else None,
        "findings": findings,
        "proposed_actions": proposed_actions,
        "applied_actions": applied_actions,
        "skipped_actions": skipped_actions,
        "duplicate_groups": duplicate_groups,
        "proposed_removals": proposed_removals,
        "applied_removals": applied_removals,
        "skipped_removals": skipped_removals,
        "stale_items": stale_items,
        "stale_reason": stale_items[0]["stale_reason"] if stale_items else None,
        "stale_checked_at": stale_checked_at,
        "stale_check_limited": stale_check_limited,
        "proposed_stale_marks": proposed_stale_marks,
        "applied_stale_marks": applied_stale_marks,
        "skipped_stale_marks": skipped_stale_marks,
        "safety_flags": {
            "source_assets_modified": False,
            "metadata_modified": False,
            "board_file_modified": board_file_modified,
            "backup_created": False,
            "repair_applied": repair_applied,
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


def propose_or_apply(board: dict[str, Any], code: str, detail: str, apply_change: Any) -> None:
    add_action(proposed_actions, code, detail)
    if apply_requested:
        apply_change()
        add_action(applied_actions, code, detail)
    else:
        add_action(skipped_actions, code, "dry-run only; set APPLY=1 after review and backup")


def trim_field(container: dict[str, Any], field: str, code: str, detail: str) -> None:
    value = container.get(field)
    if isinstance(value, str):
        trimmed = value.strip()
        if trimmed != value:
            propose_or_apply(container, code, detail, lambda: container.__setitem__(field, trimmed))


def normalize_item_tags(item: dict[str, Any], index: int) -> None:
    if "tags" not in item:
        propose_or_apply(
            item,
            "add_missing_item_tags",
            f"items[{index}].tags is missing; set to []",
            lambda: item.__setitem__("tags", []),
        )
        return
    tags = item.get("tags")
    if not isinstance(tags, list):
        add_finding("warning", "unsafe_tags_repair_denied", f"items[{index}].tags is not a list; not repaired")
        return

    next_tags: list[str] = []
    seen: set[str] = set()
    changed = False
    for tag in tags:
        if not isinstance(tag, str):
            changed = True
            continue
        normalized = tag.strip()
        if not normalized:
            changed = True
            continue
        if normalized in seen:
            changed = True
            continue
        seen.add(normalized)
        next_tags.append(normalized)
        if normalized != tag:
            changed = True

    if changed:
        propose_or_apply(
            item,
            "normalize_item_tags",
            f"items[{index}].tags normalized by trimming/removing empty or duplicate tags",
            lambda: item.__setitem__("tags", next_tags),
        )


def item_label(item: Any, index: int) -> str:
    if not isinstance(item, dict):
        return f"items[{index}]"
    item_id = item.get("item_id")
    card_id = item.get("card_id")
    if isinstance(item_id, str) and item_id:
        return item_id
    if isinstance(card_id, str) and card_id:
        return card_id
    return f"items[{index}]"


def conflict_reason(preserved: dict[str, Any], duplicate: dict[str, Any]) -> str:
    fields = ("selected_reason", "tags", "name", "asset_type", "relative_runtime_path")
    differences = [field for field in fields if preserved.get(field) != duplicate.get(field)]
    if not differences:
        return ""
    return "different " + ", ".join(differences)


def add_duplicate_group(key_type: str, key: str, indices: list[int], items: list[Any]) -> None:
    preserved_index = indices[0]
    preserved = items[preserved_index]
    duplicate_indices = indices[1:]
    duplicate_item_ids: list[str] = []
    conflict_reasons: list[str] = []
    for duplicate_index in duplicate_indices:
        duplicate = items[duplicate_index]
        duplicate_item_ids.append(item_label(duplicate, duplicate_index))
        if isinstance(preserved, dict) and isinstance(duplicate, dict):
            reason = conflict_reason(preserved, duplicate)
            if reason:
                conflict_reasons.append(reason)
    duplicate_groups.append(
        {
            "duplicate_key_type": key_type,
            "duplicate_key": key,
            "preserved_item_id": item_label(preserved, preserved_index),
            "duplicate_item_ids": duplicate_item_ids,
            "conflict_reason": "; ".join(sorted(set(conflict_reasons))),
        }
    )


def collect_duplicate_removals(items: list[Any]) -> set[int]:
    removals: set[int] = set()
    for key_type, field in (
        ("item_id", "item_id"),
        ("card_id", "card_id"),
        ("relative_runtime_path", "relative_runtime_path"),
    ):
        seen: dict[str, list[int]] = {}
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                continue
            value = item.get(field)
            if not isinstance(value, str) or not value:
                continue
            seen.setdefault(value, []).append(index)
        for key, indices in seen.items():
            if len(indices) <= 1:
                continue
            add_duplicate_group(key_type, key, indices, items)
            removals.update(indices[1:])
    return removals


def is_relative_path_safe(value: str) -> bool:
    path = Path(value)
    if path.is_absolute() or value.startswith(("~", "/")):
        return False
    return ".." not in path.parts


def is_under_path(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except (OSError, ValueError):
        return False


def is_under_allowlisted_runtime_root(path: Path) -> bool:
    return any(is_under_path(path, root) for root in ALLOWLISTED_RUNTIME_ROOTS)


def expected_card_type(path: Path) -> str | None:
    suffix = path.suffix.lower()
    if suffix in {".png", ".jpg", ".jpeg", ".webp"}:
        return "image"
    if suffix == ".svg":
        return "drawing_svg"
    return None


def safe_existing_file(path: Path) -> bool:
    try:
        return path.is_file()
    except OSError:
        return False


def detect_stale_item(item: Any, index: int) -> dict[str, Any] | None:
    global stale_check_limited

    if not isinstance(item, dict):
        return {
            "item_index": index,
            "item_id": None,
            "card_id": None,
            "relative_runtime_path": None,
            "metadata_path": None,
            "stale_reason": "item_not_object",
            "stale_reasons": ["item_not_object"],
            "stale_checked_at": stale_checked_at,
            "asset_exists": None,
            "metadata_exists": None,
            "output_card_exists": None,
        }

    reasons: list[str] = []
    asset_exists: bool | None = None
    metadata_exists: bool | None = None
    output_card_exists: bool | None = None
    asset_path: Path | None = None

    relative_runtime_path = item.get("relative_runtime_path")
    if not isinstance(relative_runtime_path, str):
        reasons.append("relative_runtime_path_missing_or_invalid")
    elif not relative_runtime_path:
        reasons.append("relative_runtime_path_missing_or_invalid")
    elif not is_relative_path_safe(relative_runtime_path):
        reasons.append("relative_runtime_path_unsafe")
    else:
        asset_path = runtime_root / relative_runtime_path
        if not is_under_allowlisted_runtime_root(asset_path):
            reasons.append("relative_runtime_path_outside_allowlist")
            stale_check_limited = True
        else:
            card_type = expected_card_type(asset_path)
            if card_type is None:
                reasons.append("unsupported_asset_extension")
            asset_exists = safe_existing_file(asset_path)
            if not asset_exists:
                reasons.append("asset_missing")
            else:
                expected_card_id = f"{card_type}:{relative_runtime_path}" if card_type else None
                card_id = item.get("card_id")
                output_card_exists = isinstance(card_id, str) and expected_card_id == card_id
                if output_card_exists is False:
                    reasons.append("output_card_missing")

    card_id = item.get("card_id")
    if not isinstance(card_id, str) or not card_id:
        reasons.append("card_id_missing_or_invalid")

    asset_type = item.get("asset_type")
    if not isinstance(asset_type, str) or not asset_type:
        reasons.append("asset_type_missing_or_invalid")

    metadata_path = item.get("metadata_path")
    if metadata_path is not None:
        if not isinstance(metadata_path, str) or not metadata_path:
            reasons.append("metadata_path_invalid")
        elif not is_relative_path_safe(metadata_path):
            reasons.append("metadata_path_unsafe")
        else:
            resolved_metadata_path = runtime_root / metadata_path
            if not is_under_allowlisted_runtime_root(resolved_metadata_path):
                reasons.append("metadata_path_outside_allowlist")
                stale_check_limited = True
            else:
                metadata_exists = safe_existing_file(resolved_metadata_path)
                if not metadata_exists:
                    reasons.append("metadata_missing")

    if not reasons:
        return None

    return {
        "item_index": index,
        "item_id": item.get("item_id"),
        "card_id": card_id if isinstance(card_id, str) else None,
        "relative_runtime_path": relative_runtime_path if isinstance(relative_runtime_path, str) else None,
        "metadata_path": metadata_path if isinstance(metadata_path, str) else None,
        "stale_reason": reasons[0],
        "stale_reasons": reasons,
        "stale_checked_at": stale_checked_at,
        "asset_exists": asset_exists,
        "metadata_exists": metadata_exists,
        "output_card_exists": output_card_exists,
    }


def write_board(next_board: dict[str, Any], original_text: str) -> None:
    global board_file_modified, repair_applied
    if board_file is None:
        add_finding("error", "repair_write_failed", "board file is unavailable")
        print("Reference board store repair failed")
        write_report(5)
    next_text = json.dumps(next_board, indent=2, sort_keys=True) + "\n"
    if next_text == original_text:
        return
    temp_file = board_file.with_name(f".{board_file.name}.repair.tmp")
    try:
        temp_file.write_text(next_text, encoding="utf-8")
        temp_file.replace(board_file)
        board_file_modified = True
        repair_applied = True
    except OSError:
        try:
            temp_file.unlink(missing_ok=True)
        except OSError:
            pass
        add_finding("error", "repair_write_failed", "could not atomically write repaired board file")
        print("Reference board store repair failed")
        write_report(5)


if not board_id:
    add_finding("error", "missing_board_id", "BOARD_ID is required")
    print("Reference board store repair failed")
    write_report(2)

if not is_safe_board_id(board_id):
    add_finding("error", "invalid_board_id", "BOARD_ID must use lowercase letters, numbers, dash, or underscore only")
    print("Reference board store repair failed")
    write_report(2)

if mode not in {"repair-schema", "remove-duplicate-items", "mark-stale-items"}:
    add_finding(
        "error",
        "unsupported_mode",
        "MODE currently supports only repair-schema, remove-duplicate-items, or mark-stale-items",
    )
    print("Reference board store repair failed")
    write_report(2)

try:
    runtime_resolved = runtime_dir.resolve(strict=True)
except OSError:
    add_finding("error", "runtime_dir_missing", "reference board runtime directory is unavailable")
    print("Reference board store repair failed")
    write_report(2)

board_file = runtime_resolved / f"{board_id}.json"
if not board_file.is_file():
    add_finding("error", "board_missing", "board file does not exist")
    print("Reference board store repair failed")
    write_report(3)

try:
    backup_dir_resolved = backup_dir.resolve(strict=True)
    backup_dir_resolved.relative_to(runtime_resolved)
    backup_found = any(backup_dir_resolved.glob(f"reference-board-{board_id}-*.json.bak"))
except (OSError, ValueError):
    backup_found = False

if apply_requested and require_backup and not backup_found:
    add_finding("error", "backup_required_missing", "APPLY=1 requires an existing backup for this board")
    print("Reference board store repair failed")
    write_report(4)

try:
    original_text = board_file.read_text(encoding="utf-8")
    board = json.loads(original_text)
except json.JSONDecodeError:
    add_finding("error", "json_malformed", "board JSON does not parse; repair cannot safely continue")
    print("Reference board store repair failed")
    write_report(1)
except OSError:
    add_finding("error", "board_file_unreadable", "board file cannot be read")
    print("Reference board store repair failed")
    write_report(5)

if not isinstance(board, dict):
    add_finding("error", "top_level_not_object", "top-level JSON must be an object; repair cannot safely continue")
    print("Reference board store repair failed")
    write_report(1)

if mode == "remove-duplicate-items":
    items = board.get("items")
    if not isinstance(items, list):
        add_finding("error", "items_not_list", "items must be a list for remove-duplicate-items")
        print("Reference board store repair failed")
        write_report(1)

    removal_indices = collect_duplicate_removals(items)
    for index in sorted(removal_indices):
        item = items[index]
        removal = {
            "item_index": index,
            "item_id": item.get("item_id") if isinstance(item, dict) else None,
            "card_id": item.get("card_id") if isinstance(item, dict) else None,
            "relative_runtime_path": item.get("relative_runtime_path") if isinstance(item, dict) else None,
        }
        proposed_removals.append(removal)
        add_action(
            proposed_actions,
            "remove_duplicate_item",
            f"remove duplicate board item at index {index}: {item_label(item, index)}",
        )
        if apply_requested:
            applied_removals.append(removal)
            add_action(
                applied_actions,
                "remove_duplicate_item",
                f"removed duplicate board item at index {index}: {item_label(item, index)}",
            )
        else:
            skipped_removals.append(removal)
            add_action(skipped_actions, "remove_duplicate_item", "dry-run only; set APPLY=1 after review and backup")

    if apply_requested and removal_indices:
        board["items"] = [item for index, item in enumerate(items) if index not in removal_indices]
        if isinstance(board.get("updated_at"), str):
            board["updated_at"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
            add_action(applied_actions, "update_board_updated_at", "updated_at set because repair changed the board")
        write_board(board, original_text)
        print("Reference board store repair applied OK")
        write_report(0)

    if apply_requested:
        print("Reference board store repair no changes needed")
        write_report(0)

    print("Reference board store repair dry-run OK")
    write_report(0)

if mode == "mark-stale-items":
    items = board.get("items")
    if not isinstance(items, list):
        add_finding("error", "items_not_list", "items must be a list for mark-stale-items")
        print("Reference board store repair failed")
        write_report(1)

    for index, item in enumerate(items):
        stale_item = detect_stale_item(item, index)
        if stale_item is None:
            continue
        stale_items.append(stale_item)
        stale_mark = {
            "item_index": stale_item["item_index"],
            "item_id": stale_item["item_id"],
            "card_id": stale_item["card_id"],
            "stale_reason": stale_item["stale_reason"],
            "stale_checked_at": stale_checked_at,
        }
        proposed_stale_marks.append(stale_mark)
        add_action(
            proposed_actions,
            "mark_stale_item",
            f"mark stale board item at index {index}: {item_label(item, index)} ({stale_item['stale_reason']})",
        )
        if apply_requested:
            if isinstance(item, dict):
                before = {field: item.get(field) for field in ("stale", "stale_reason", "stale_checked_at")}
                item["stale"] = True
                item["stale_reason"] = stale_item["stale_reason"]
                item["stale_checked_at"] = stale_checked_at
                after = {field: item.get(field) for field in ("stale", "stale_reason", "stale_checked_at")}
                if before != after:
                    applied_stale_marks.append(stale_mark)
                    add_action(
                        applied_actions,
                        "mark_stale_item",
                        f"marked stale board item at index {index}: {item_label(item, index)}",
                    )
                else:
                    skipped_stale_marks.append(stale_mark)
                    add_action(skipped_actions, "mark_stale_item", "stale marker already matched current check")
            else:
                skipped_stale_marks.append(stale_mark)
                add_action(skipped_actions, "mark_stale_item", "item is not an object; stale marker not applied")
        else:
            skipped_stale_marks.append(stale_mark)
            add_action(skipped_actions, "mark_stale_item", "dry-run only; set APPLY=1 after review and backup")

    if any(isinstance(item, dict) and item.get("stale") is True for item in items):
        add_finding("info", "stale_marker_cleanup_deferred", "existing stale markers are not removed in this milestone")

    if apply_requested and applied_stale_marks:
        if isinstance(board.get("updated_at"), str):
            board["updated_at"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
            add_action(applied_actions, "update_board_updated_at", "updated_at set because repair changed the board")
        write_board(board, original_text)
        print("Reference board store repair applied OK")
        write_report(0)

    if apply_requested:
        print("Reference board store repair no changes needed")
        write_report(0)

    print("Reference board store repair dry-run OK")
    write_report(0)

if "board_id" not in board:
    add_finding("warning", "unsafe_board_id_repair_denied", "missing board_id is not repaired")
if "title" not in board:
    add_finding("warning", "unsafe_title_repair_denied", "missing title is not repaired")
if "created_at" not in board:
    add_finding("warning", "unsafe_created_at_repair_denied", "missing created_at is not repaired")
if "updated_at" not in board:
    add_finding("warning", "unsafe_updated_at_repair_denied", "missing updated_at is not repaired")

trim_field(board, "title", "trim_board_title", "board title will be trimmed")
trim_field(board, "description", "trim_board_description", "board description will be trimmed")

if "safety_label" not in board:
    propose_or_apply(
        board,
        "add_board_safety_label",
        'board safety_label is missing; set to "visual_reference_only"',
        lambda: board.__setitem__("safety_label", "visual_reference_only"),
    )

if "items" not in board:
    propose_or_apply(board, "add_missing_items", "items is missing; set to []", lambda: board.__setitem__("items", []))
elif not isinstance(board.get("items"), list):
    add_finding("warning", "unsafe_items_repair_denied", "items exists but is not a list; not repaired")

items = board.get("items")
if isinstance(items, list):
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            add_finding("warning", "unsafe_item_repair_denied", f"items[{index}] is not an object; not repaired")
            continue
        if "item_id" not in item:
            add_finding("warning", "unsafe_item_id_repair_denied", f"items[{index}].item_id is missing; not repaired")
        if "card_id" not in item:
            add_finding("warning", "unsafe_card_id_repair_denied", f"items[{index}].card_id is missing; not repaired")
        if "relative_runtime_path" not in item:
            add_finding("warning", "unsafe_relative_runtime_path_repair_denied", f"items[{index}].relative_runtime_path is missing; not repaired")
        if "asset_type" not in item:
            add_finding("warning", "unsafe_asset_type_repair_denied", f"items[{index}].asset_type is missing; not repaired")

        trim_field(item, "selected_reason", "trim_item_selected_reason", f"items[{index}].selected_reason will be trimmed")
        if "selected_reason" not in item:
            propose_or_apply(
                item,
                "add_missing_item_selected_reason",
                f"items[{index}].selected_reason is missing; set to empty string",
                lambda item=item: item.__setitem__("selected_reason", ""),
            )
        normalize_item_tags(item, index)

if apply_requested and proposed_actions:
    now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    if isinstance(board.get("updated_at"), str):
        board["updated_at"] = now
        add_action(applied_actions, "update_board_updated_at", "updated_at set because repair changed the board")
    write_board(board, original_text)

if apply_requested:
    if board_file_modified:
        print("Reference board store repair applied OK")
        write_report(0)
    print("Reference board store repair no changes needed")
    write_report(0)

if proposed_actions:
    print("Reference board store repair dry-run OK")
    write_report(1)

print("Reference board store repair dry-run OK")
write_report(0)
PY
