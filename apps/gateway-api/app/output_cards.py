from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
MEDIA_IMAGES_ROOT = RUNTIME_ROOT / "media" / "outputs" / "images"
PERGOLA_DRAWINGS_ROOT = RUNTIME_ROOT / "pergola" / "drawings"
DRAWINGS_ROOT = RUNTIME_ROOT / "drawings"
ALLOWLISTED_ROOTS = (MEDIA_IMAGES_ROOT, PERGOLA_DRAWINGS_ROOT, DRAWINGS_ROOT)

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
DRAWING_EXTENSIONS = {".svg"}
SUPPORTED_EXTENSIONS = IMAGE_EXTENSIONS | DRAWING_EXTENSIONS
DENIED_EXTENSIONS = {".gguf", ".safetensors", ".pt", ".pth", ".ckpt"}
PREVIEW_MEDIA_TYPES = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
}
MAX_OUTPUT_CARDS = 100
MAX_METADATA_BYTES = 128 * 1024


def build_output_cards(max_cards: int = MAX_OUTPUT_CARDS) -> dict[str, Any]:
    cards = _scan_cards(max(0, int(max_cards)))
    return {
        "status": "ok",
        "service": "gateway-media-output-cards",
        "safety": {
            "read_only": True,
            "starts_services": False,
            "stops_services": False,
            "real_generation_trigger": False,
            "arbitrary_shell": False,
        },
        "allowlisted_roots": [str(root) for root in ALLOWLISTED_ROOTS],
        "max_cards": MAX_OUTPUT_CARDS,
        "cards": cards,
    }


def find_output_card_by_id(card_id: str, max_cards: int = MAX_OUTPUT_CARDS) -> dict[str, Any] | None:
    for card in _scan_cards(max(0, int(max_cards))):
        if card.get("id") == card_id:
            return card
    return None


def is_preview_extension_allowed(path: Path) -> bool:
    return path.suffix.lower() in PREVIEW_MEDIA_TYPES


def preview_media_type_for_path(path: Path) -> str | None:
    return PREVIEW_MEDIA_TYPES.get(path.suffix.lower())


def safe_preview_path_for_card(card: dict[str, Any]) -> tuple[Path | None, str | None]:
    if card.get("type") != "image" or card.get("preview_available") is not True:
        return None, "preview_unavailable"

    raw_path = card.get("path")
    if not isinstance(raw_path, str) or not raw_path:
        return None, "preview_blocked"

    path = Path(raw_path)
    if _has_hidden_part(path):
        return None, "preview_blocked"
    if not is_preview_extension_allowed(path):
        return None, "preview_blocked"
    if not _is_under_allowlisted_root(path):
        return None, "preview_blocked"

    try:
        resolved = path.resolve(strict=True)
    except OSError:
        return None, "preview_blocked"

    if _has_hidden_part(resolved):
        return None, "preview_blocked"
    if not resolved.is_file():
        return None, "preview_blocked"
    if not _is_under_allowlisted_root(resolved):
        return None, "preview_blocked"
    if not is_preview_extension_allowed(resolved):
        return None, "preview_blocked"

    return resolved, None


def is_metadata_json_allowed(path: Path) -> bool:
    return path.suffix.lower() == ".json" and not _has_hidden_part(path) and _is_under_allowlisted_root(path)


def safe_metadata_path_for_card(card: dict[str, Any]) -> tuple[Path | None, str | None]:
    if card.get("metadata_available") is not True:
        return None, "metadata_unavailable"

    raw_asset_path = card.get("path")
    raw_metadata_path = card.get("metadata_path")
    if not isinstance(raw_asset_path, str) or not isinstance(raw_metadata_path, str):
        return None, "metadata_blocked"

    asset_path = Path(raw_asset_path)
    metadata_path = Path(raw_metadata_path)
    if not is_metadata_json_allowed(metadata_path):
        return None, "metadata_blocked"
    if not _is_under_allowlisted_root(asset_path):
        return None, "metadata_blocked"

    try:
        resolved_asset = asset_path.resolve(strict=True)
        resolved_metadata = metadata_path.resolve(strict=True)
    except OSError:
        return None, "metadata_unavailable"

    if _has_hidden_part(resolved_asset) or _has_hidden_part(resolved_metadata):
        return None, "metadata_blocked"
    if not resolved_asset.is_file() or not resolved_metadata.is_file():
        return None, "metadata_unavailable"
    if not _is_under_allowlisted_root(resolved_asset) or not _is_under_allowlisted_root(resolved_metadata):
        return None, "metadata_blocked"
    if resolved_metadata != resolved_asset.with_suffix(".json"):
        return None, "metadata_blocked"

    try:
        if resolved_metadata.stat().st_size > MAX_METADATA_BYTES:
            return None, "metadata_blocked"
    except OSError:
        return None, "metadata_unavailable"

    return resolved_metadata, None


def load_output_card_metadata(card: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    metadata_path, error = safe_metadata_path_for_card(card)
    if error is not None or metadata_path is None:
        return None, error

    try:
        raw_metadata = metadata_path.read_text(encoding="utf-8")
        metadata = json.loads(raw_metadata)
    except json.JSONDecodeError:
        return None, "metadata_invalid"
    except OSError:
        return None, "metadata_unavailable"

    if not isinstance(metadata, dict):
        return None, "metadata_invalid"
    return metadata, None


def _scan_cards(max_cards: int) -> list[dict[str, Any]]:
    paths: list[Path] = []
    for root in ALLOWLISTED_ROOTS:
        paths.extend(_scan_root(root))

    paths.sort(key=_modified_timestamp, reverse=True)
    cards: list[dict[str, Any]] = []
    for path in paths[:max_cards]:
        card = _build_card(path)
        if card is not None:
            cards.append(card)
    return cards


def _scan_root(root: Path) -> list[Path]:
    if not root.exists() or not root.is_dir():
        return []

    results: list[Path] = []
    try:
        for path in root.rglob("*"):
            if _is_supported_output(path):
                results.append(path)
    except OSError:
        return results
    return results


def _is_supported_output(path: Path) -> bool:
    if not path.is_file():
        return False
    if _has_hidden_part(path):
        return False
    suffix = path.suffix.lower()
    if suffix in DENIED_EXTENSIONS:
        return False
    if suffix not in SUPPORTED_EXTENSIONS:
        return False
    return _is_under_allowlisted_root(path)


def _has_hidden_part(path: Path) -> bool:
    return any(part.startswith(".") for part in path.parts)


def _is_under_allowlisted_root(path: Path) -> bool:
    try:
        resolved = path.resolve()
    except OSError:
        return False
    for root in ALLOWLISTED_ROOTS:
        try:
            resolved.relative_to(root.resolve())
            return True
        except ValueError:
            continue
        except OSError:
            continue
    return False


def _build_card(path: Path) -> dict[str, Any] | None:
    try:
        stat = path.stat()
    except OSError:
        return None
    card_type = _card_type(path)
    metadata_path = path.with_suffix(".json")
    metadata_available = metadata_path.is_file() and not _has_hidden_part(metadata_path)
    card = {
        "id": f"{card_type}:{path.name}",
        "type": card_type,
        "name": path.name,
        "path": str(path),
        "relative_runtime_path": _relative_runtime_path(path),
        "modified": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        "size_bytes": stat.st_size,
        "preview_available": card_type == "image",
        "source": _source(path),
        "tags": _tags(path, card_type),
        "safety_label": _safety_label(card_type),
        "metadata_available": metadata_available,
        "metadata_path": str(metadata_path) if metadata_available else None,
        "notes": None,
    }
    return card


def _card_type(path: Path) -> str:
    if path.suffix.lower() in IMAGE_EXTENSIONS:
        return "image"
    return "drawing_svg"


def _source(path: Path) -> str:
    path_text = str(path)
    if "/media/outputs/images" in path_text:
        return "comfyui"
    if "/pergola/drawings" in path_text or "/drawings" in path_text:
        return "deterministic-svg"
    return "generated-output"


def _tags(path: Path, card_type: str) -> list[str]:
    tags = [card_type]
    if card_type == "image":
        tags.append("image")
    if card_type == "drawing_svg":
        tags.extend(["drawing", "svg"])
    if "/pergola/" in str(path):
        tags.append("pergola")
    return _dedupe_tags(tags)


def _dedupe_tags(tags: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for tag in tags:
        if tag in seen:
            continue
        seen.add(tag)
        result.append(tag)
    return result


def _safety_label(card_type: str) -> str:
    if card_type == "image":
        return "visual_reference_only"
    return "draft_drawing"


def _relative_runtime_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(RUNTIME_ROOT.resolve()))
    except (OSError, ValueError):
        return path.name


def _modified_timestamp(path: Path) -> float:
    try:
        return path.stat().st_mtime
    except OSError:
        return 0.0
