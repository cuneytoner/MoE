from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REFERENCE_BOARDS_ROOT = Path("/home/cuneyt/MoE/runtime/reference-boards")
MAX_REFERENCE_BOARD_BYTES = 256 * 1024
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")
ITEM_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")


def ensure_reference_boards_root() -> Path:
    REFERENCE_BOARDS_ROOT.mkdir(parents=True, exist_ok=True)
    return REFERENCE_BOARDS_ROOT


def sanitize_board_id(board_id: str) -> str:
    candidate = board_id.strip()
    if not candidate:
        raise ValueError("board_id is required")
    if "/" in candidate or "\\" in candidate or ".." in candidate:
        raise ValueError("board_id must not contain path separators or traversal")
    if candidate.startswith("."):
        raise ValueError("board_id must not be hidden")
    if not BOARD_ID_PATTERN.fullmatch(candidate):
        raise ValueError("board_id may contain only lowercase letters, numbers, dash, and underscore")
    return candidate


def board_path_for_id(board_id: str) -> Path:
    safe_board_id = sanitize_board_id(board_id)
    return REFERENCE_BOARDS_ROOT / f"{safe_board_id}.json"


def is_safe_board_path(path: Path) -> bool:
    if path.suffix.lower() != ".json":
        return False
    if any(part.startswith(".") for part in path.parts):
        return False
    try:
        resolved = path.resolve()
        root = REFERENCE_BOARDS_ROOT.resolve()
        resolved.relative_to(root)
    except (OSError, ValueError):
        return False
    return resolved.name == path.name and BOARD_ID_PATTERN.fullmatch(resolved.stem) is not None


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def list_reference_board_files() -> list[Path]:
    root = ensure_reference_boards_root()
    files: list[Path] = []
    for path in root.glob("*.json"):
        if is_safe_board_path(path) and path.is_file():
            files.append(path)
    return sorted(files)


def list_reference_boards() -> list[dict[str, Any]]:
    boards: list[dict[str, Any]] = []
    for path in list_reference_board_files():
        try:
            board = load_reference_board(path.stem)
        except (FileNotFoundError, ValueError, json.JSONDecodeError, OSError):
            continue
        items = board.get("items")
        boards.append(
            {
                "board_id": board.get("board_id"),
                "title": board.get("title"),
                "description": board.get("description"),
                "created_at": board.get("created_at"),
                "updated_at": board.get("updated_at"),
                "safety_label": board.get("safety_label"),
                "item_count": len(items) if isinstance(items, list) else 0,
                "path": str(path),
            }
        )
    return sorted(boards, key=lambda board: str(board.get("updated_at") or ""), reverse=True)


def item_id_for_card_id(card_id: str) -> str:
    if ":" in card_id:
        prefix, suffix = card_id.split(":", 1)
        item_id = f"{prefix.lower()}-{re.sub(r'[^a-z0-9]+', '_', suffix.lower()).strip('_')}"
    else:
        item_id = re.sub(r"[^a-z0-9]+", "_", card_id.lower()).strip("_")
    if not item_id:
        raise ValueError("card_id cannot produce item_id")
    return item_id[:120]


def add_item_to_reference_board(board_id: str, item: dict[str, Any]) -> dict[str, Any]:
    board = load_reference_board(board_id)
    errors = validate_reference_board_item_shape(item)
    if errors:
        raise ValueError("; ".join(errors))

    items = board.setdefault("items", [])
    if not isinstance(items, list):
        raise ValueError("items must be a list")
    if any(existing.get("card_id") == item.get("card_id") for existing in items if isinstance(existing, dict)):
        raise ValueError("reference_board_item_exists")

    items.append(item)
    write_reference_board(board)
    return load_reference_board(board_id)


def remove_item_from_reference_board(board_id: str, item_id: str) -> dict[str, Any]:
    if not ITEM_ID_PATTERN.fullmatch(item_id):
        raise ValueError("invalid_item_id")
    board = load_reference_board(board_id)
    items = board.get("items")
    if not isinstance(items, list):
        raise ValueError("items must be a list")

    next_items = [item for item in items if not (isinstance(item, dict) and item.get("item_id") == item_id)]
    if len(next_items) == len(items):
        raise ValueError("reference_board_item_not_found")
    board["items"] = next_items
    write_reference_board(board)
    return load_reference_board(board_id)


def update_reference_board_item(board_id: str, item_id: str, updates: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    if not ITEM_ID_PATTERN.fullmatch(item_id):
        raise ValueError("invalid_item_id")
    allowed_fields = {"selected_reason", "tags"}
    if not any(field in updates for field in allowed_fields):
        raise ValueError("invalid_item_update")
    blocked_fields = set(updates) - allowed_fields
    if blocked_fields:
        raise ValueError("invalid_item_update")

    board = load_reference_board(board_id)
    items = board.get("items")
    if not isinstance(items, list):
        raise ValueError("items must be a list")

    updated_item: dict[str, Any] | None = None
    for item in items:
        if not isinstance(item, dict) or item.get("item_id") != item_id:
            continue
        next_item = dict(item)
        if "selected_reason" in updates:
            selected_reason = updates["selected_reason"]
            next_item["selected_reason"] = selected_reason.strip() if isinstance(selected_reason, str) and selected_reason.strip() else None
        if "tags" in updates:
            tags = updates["tags"]
            if tags is None:
                next_item["tags"] = []
            else:
                next_item["tags"] = list(tags)
        errors = validate_reference_board_item_shape(next_item)
        if errors:
            raise ValueError("; ".join(errors))
        item.clear()
        item.update(next_item)
        updated_item = dict(next_item)
        break

    if updated_item is None:
        raise ValueError("reference_board_item_not_found")

    write_reference_board(board)
    updated_board = load_reference_board(board_id)
    for item in updated_board.get("items", []):
        if isinstance(item, dict) and item.get("item_id") == item_id:
            return updated_board, dict(item)
    raise ValueError("reference_board_item_not_found")


def load_reference_board(board_id: str) -> dict[str, Any]:
    path = board_path_for_id(board_id)
    if not is_safe_board_path(path):
        raise ValueError("unsafe reference board path")
    if not path.is_file():
        raise FileNotFoundError(str(path))
    if path.stat().st_size > MAX_REFERENCE_BOARD_BYTES:
        raise ValueError("reference board file is too large")

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("reference board JSON must be an object")
    errors = validate_reference_board_shape(data)
    if errors:
        raise ValueError("; ".join(errors))
    return data


def write_reference_board(board: dict[str, Any]) -> Path:
    errors = validate_reference_board_shape(board)
    if errors:
        raise ValueError("; ".join(errors))

    path = board_path_for_id(str(board["board_id"]))
    if not is_safe_board_path(path):
        raise ValueError("unsafe reference board path")

    now = utc_now_iso()
    board = dict(board)
    board.setdefault("created_at", now)
    board["updated_at"] = now

    payload = json.dumps(board, indent=2, sort_keys=True) + "\n"
    encoded = payload.encode("utf-8")
    if len(encoded) > MAX_REFERENCE_BOARD_BYTES:
        raise ValueError("reference board JSON exceeds size limit")

    ensure_reference_boards_root()
    path.write_bytes(encoded)
    return path


def build_empty_reference_board(board_id: str, title: str, description: str | None = None) -> dict[str, Any]:
    safe_board_id = sanitize_board_id(board_id)
    now = utc_now_iso()
    return {
        "schema_version": "1.0",
        "board_id": safe_board_id,
        "title": title,
        "description": description,
        "created_at": now,
        "updated_at": now,
        "safety_label": "visual_reference_only",
        "items": [],
    }


def validate_reference_board_shape(board: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if not isinstance(board, dict):
        return ["board must be an object"]

    if not board.get("schema_version"):
        errors.append("schema_version is required")
    if not board.get("board_id"):
        errors.append("board_id is required")
    else:
        try:
            sanitize_board_id(str(board["board_id"]))
        except ValueError as exc:
            errors.append(str(exc))
    if not board.get("title"):
        errors.append("title is required")

    items = board.get("items")
    if not isinstance(items, list):
        errors.append("items must be a list")
        return errors

    for index, item in enumerate(items):
        if not isinstance(item, dict):
            errors.append(f"items[{index}] must be an object")
            continue
        errors.extend(f"items[{index}].{error}" for error in validate_reference_board_item_shape(item))
    return errors


def validate_reference_board_item_shape(item: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if not isinstance(item, dict):
        return ["item must be an object"]

    for field in ("item_id", "card_id", "asset_type", "name", "relative_runtime_path", "safety_label", "added_at"):
        if not item.get(field):
            errors.append(f"{field} is required")

    item_id = item.get("item_id")
    if isinstance(item_id, str) and not ITEM_ID_PATTERN.fullmatch(item_id):
        errors.append("item_id contains unsupported characters")

    selected_reason = item.get("selected_reason")
    if selected_reason is not None and not isinstance(selected_reason, str):
        errors.append("selected_reason must be a string")
    if isinstance(selected_reason, str) and len(selected_reason) > 500:
        errors.append("selected_reason is too long")

    tags = item.get("tags")
    if not isinstance(tags, list):
        errors.append("tags must be a list")
    elif len(tags) > 20:
        errors.append("tags has too many values")
    else:
        for index, tag in enumerate(tags):
            if not isinstance(tag, str) or not tag:
                errors.append(f"tags[{index}] must be a non-empty string")
            elif len(tag) > 60:
                errors.append(f"tags[{index}] is too long")

    relative_runtime_path = item.get("relative_runtime_path")
    if relative_runtime_path is not None:
        if not isinstance(relative_runtime_path, str):
            errors.append("relative_runtime_path must be a string")
        else:
            if relative_runtime_path.startswith("/"):
                errors.append("relative_runtime_path must not be absolute")
            if ".." in Path(relative_runtime_path).parts:
                errors.append("relative_runtime_path must not contain traversal")
    return errors
