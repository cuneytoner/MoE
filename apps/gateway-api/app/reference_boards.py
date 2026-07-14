from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.output_cards import find_output_card_by_id, load_output_card_metadata


REFERENCE_BOARDS_ROOT = Path("/home/cuneyt/MoE/runtime/reference-boards")
MAX_REFERENCE_BOARD_BYTES = 256 * 1024
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")
ITEM_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")
METADATA_SUMMARY_FIELDS = (
    "source",
    "script",
    "workflow",
    "model_name",
    "model_family",
    "prompt",
    "seed",
    "width",
    "height",
    "steps",
    "drawing_kind",
    "geometry",
    "units",
    "project",
    "notes",
)
HOST_PATH_MARKERS = ("/home/", "/mnt/", "/media/", "/workspace/", "/app/")


class ReferenceBoardMalformedError(ValueError):
    """Raised when a board file exists but cannot be trusted as board JSON."""


class ReferenceBoardStoreUnavailableError(RuntimeError):
    """Raised when the runtime board store cannot be read or written."""


def ensure_reference_boards_root() -> Path:
    try:
        REFERENCE_BOARDS_ROOT.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise ReferenceBoardStoreUnavailableError("reference board store is unavailable") from exc
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
        except (FileNotFoundError, ValueError, ReferenceBoardStoreUnavailableError, OSError):
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


def build_reference_board_json_export(board_id: str) -> dict[str, Any]:
    board = load_reference_board(board_id)
    items = board.get("items")
    if not isinstance(items, list):
        raise ValueError("items must be a list")

    return {
        "schema_version": "1.0",
        "export_type": "reference_board_review_pack",
        "exported_at": utc_now_iso(),
        "board": {
            "board_id": board.get("board_id"),
            "title": board.get("title"),
            "description": board.get("description"),
            "created_at": board.get("created_at"),
            "updated_at": board.get("updated_at"),
            "safety_label": board.get("safety_label"),
            "item_count": len(items),
        },
        "items": [_export_item(item) for item in items if isinstance(item, dict)],
        "safety": {
            "review_only": True,
            "source_assets_copied": False,
            "source_assets_deleted": False,
            "generation_triggered": False,
        },
    }


def build_reference_board_markdown_export(board_id: str) -> str:
    review_pack = build_reference_board_json_export(board_id)
    board = review_pack["board"]
    safety = review_pack["safety"]
    title = _markdown_text(board.get("title") or board.get("board_id") or "Reference Board")

    lines = [
        f"# Reference Board Review Pack: {title}",
        "",
        "## Board",
        "",
        f"- Board ID: {_markdown_text(board.get('board_id'))}",
        f"- Description: {_markdown_text(board.get('description'))}",
        f"- Created: {_markdown_text(board.get('created_at'))}",
        f"- Updated: {_markdown_text(board.get('updated_at'))}",
        f"- Safety label: {_markdown_text(board.get('safety_label'))}",
        f"- Item count: {_markdown_text(board.get('item_count'))}",
        "",
        "## Safety",
        "",
        f"- Review only: {_markdown_bool(safety.get('review_only'))}",
        f"- Source assets copied: {_markdown_bool(safety.get('source_assets_copied'))}",
        f"- Source assets deleted: {_markdown_bool(safety.get('source_assets_deleted'))}",
        f"- Generation triggered: {_markdown_bool(safety.get('generation_triggered'))}",
        "",
        "## Items",
        "",
    ]

    items = review_pack.get("items")
    if not isinstance(items, list) or not items:
        lines.extend(["No items.", ""])
    else:
        for index, item in enumerate(items, start=1):
            if not isinstance(item, dict):
                continue
            _append_markdown_item(lines, index, item)

    return "\n".join(lines).rstrip() + "\n"


def build_reference_board_download_filename(board_id: str, extension: str) -> str:
    safe_board_id = sanitize_board_id(board_id)
    if extension not in {"json", "md"}:
        raise ValueError("unsupported reference board download extension")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    return f"reference-board-{safe_board_id}-{timestamp}.{extension}"


def summarize_item_metadata(item: dict[str, Any]) -> dict[str, Any] | None:
    card_id = item.get("card_id")
    if not isinstance(card_id, str) or not card_id:
        return {"available": False, "reason": "metadata_unavailable"}

    card = find_output_card_by_id(card_id)
    if card is None:
        return {"available": False, "reason": "output_card_not_found"}

    metadata, error = load_output_card_metadata(card)
    if error is not None or metadata is None:
        return {"available": False, "reason": error or "metadata_unavailable"}

    summary: dict[str, Any] = {}
    for field in METADATA_SUMMARY_FIELDS:
        if field not in metadata:
            continue
        value = _safe_metadata_summary_value(metadata[field])
        if value is not None:
            summary[field] = value

    if not summary:
        return {"available": False, "reason": "metadata_empty"}
    return summary


def load_reference_board(board_id: str) -> dict[str, Any]:
    path = board_path_for_id(board_id)
    if not is_safe_board_path(path):
        raise ValueError("unsafe reference board path")
    if not path.is_file():
        raise FileNotFoundError(str(path))
    try:
        if path.stat().st_size > MAX_REFERENCE_BOARD_BYTES:
            raise ReferenceBoardMalformedError("reference board file exceeds size limit")
        raw_board = path.read_text(encoding="utf-8")
    except ReferenceBoardMalformedError:
        raise
    except OSError as exc:
        raise ReferenceBoardStoreUnavailableError("reference board store is unavailable") from exc

    try:
        data = json.loads(raw_board)
    except json.JSONDecodeError as exc:
        raise ReferenceBoardMalformedError("reference board JSON is malformed") from exc
    if not isinstance(data, dict):
        raise ReferenceBoardMalformedError("reference board JSON must be an object")
    errors = validate_reference_board_shape(data)
    if errors:
        raise ReferenceBoardMalformedError("reference board JSON failed validation")
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
    try:
        path.write_bytes(encoded)
    except OSError as exc:
        raise ReferenceBoardStoreUnavailableError("reference board store is unavailable") from exc
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


def _export_item(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "item_id": item.get("item_id"),
        "card_id": item.get("card_id"),
        "asset_type": item.get("asset_type"),
        "name": item.get("name"),
        "relative_runtime_path": item.get("relative_runtime_path"),
        "selected_reason": item.get("selected_reason"),
        "tags": item.get("tags") if isinstance(item.get("tags"), list) else [],
        "safety_label": item.get("safety_label"),
        "added_at": item.get("added_at"),
        "metadata_summary": summarize_item_metadata(item),
    }


def _safe_metadata_summary_value(value: Any) -> Any:
    if value is None or isinstance(value, (bool, int, float)):
        return value
    if isinstance(value, str):
        if _looks_like_absolute_host_path(value) or _looks_like_secret(value):
            return None
        return value
    if isinstance(value, list):
        safe_items = [_safe_metadata_summary_value(item) for item in value]
        return [item for item in safe_items if item is not None]
    if isinstance(value, dict):
        safe_dict: dict[str, Any] = {}
        for key, child in value.items():
            if not isinstance(key, str) or _looks_like_secret(key):
                continue
            safe_value = _safe_metadata_summary_value(child)
            if safe_value is not None:
                safe_dict[key] = safe_value
        return safe_dict
    return None


def _looks_like_absolute_host_path(value: str) -> bool:
    if value.startswith(("/", "~")):
        return True
    return any(marker in value for marker in HOST_PATH_MARKERS)


def _looks_like_secret(value: str) -> bool:
    lowered = value.lower()
    return any(marker in lowered for marker in ("secret", "token", "api_key", "apikey", "password"))


def _append_markdown_item(lines: list[str], index: int, item: dict[str, Any]) -> None:
    lines.extend(
        [
            f"## Item {index}: {_markdown_text(item.get('name'))}",
            "",
            f"- Item ID: {_markdown_text(item.get('item_id'))}",
            f"- Card ID: {_markdown_text(item.get('card_id'))}",
            f"- Asset type: {_markdown_text(item.get('asset_type'))}",
            f"- Relative runtime path: {_markdown_text(item.get('relative_runtime_path'))}",
            f"- Safety label: {_markdown_text(item.get('safety_label'))}",
            f"- Added at: {_markdown_text(item.get('added_at'))}",
            f"- Selected reason: {_markdown_text(item.get('selected_reason'))}",
            f"- Tags: {_markdown_tags(item.get('tags'))}",
            "",
            "### Metadata summary",
            "",
        ]
    )
    _append_markdown_metadata_summary(lines, item.get("metadata_summary"))
    lines.append("")


def _append_markdown_metadata_summary(lines: list[str], metadata_summary: Any) -> None:
    if not isinstance(metadata_summary, dict) or metadata_summary.get("available") is False:
        reason = metadata_summary.get("reason") if isinstance(metadata_summary, dict) else "metadata_unavailable"
        lines.append(f"- available: false ({_markdown_text(reason)})")
        return

    for field in (
        "source",
        "script",
        "workflow",
        "model_name",
        "model_family",
        "prompt",
        "seed",
        "width",
        "height",
        "steps",
        "drawing_kind",
        "units",
        "project",
        "notes",
    ):
        if field in metadata_summary:
            lines.append(f"- {field}: {_markdown_text(metadata_summary.get(field))}")

    geometry = metadata_summary.get("geometry")
    if geometry is not None:
        lines.extend(["- geometry summary:", "", "```json", _markdown_text(json.dumps(geometry, indent=2, sort_keys=True)), "```"])


def _markdown_text(value: Any) -> str:
    if value is None or value == "":
        return "not provided"
    if isinstance(value, bool):
        return _markdown_bool(value)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, dict)):
        text = json.dumps(value, sort_keys=True)
    else:
        text = str(value)
    return text.replace("<", "&lt;").replace(">", "&gt;")


def _markdown_bool(value: Any) -> str:
    return "true" if value is True else "false"


def _markdown_tags(value: Any) -> str:
    if not isinstance(value, list) or not value:
        return "not provided"
    return ", ".join(_markdown_text(tag) for tag in value)


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
