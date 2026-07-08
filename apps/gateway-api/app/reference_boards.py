from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REFERENCE_BOARDS_ROOT = Path("/home/cuneyt/MoE/runtime/reference-boards")
MAX_REFERENCE_BOARD_BYTES = 256 * 1024
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")


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
        relative_runtime_path = item.get("relative_runtime_path")
        if relative_runtime_path is None:
            continue
        if not isinstance(relative_runtime_path, str):
            errors.append(f"items[{index}].relative_runtime_path must be a string")
            continue
        if relative_runtime_path.startswith("/"):
            errors.append(f"items[{index}].relative_runtime_path must not be absolute")
        if ".." in Path(relative_runtime_path).parts:
            errors.append(f"items[{index}].relative_runtime_path must not contain traversal")
    return errors
