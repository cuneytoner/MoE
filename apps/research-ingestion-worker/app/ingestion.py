from pathlib import Path
from typing import Any

import yaml

from app.config import Settings

SUPPORTED_LOCAL_TYPES = {"local_markdown", "local_text"}
SKIPPED_DIR_PARTS = {
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    "node_modules",
    "models",
    "runtime",
    "data",
    "checkpoints",
    "custom_nodes",
}


def load_sources(settings: Settings, source_set: str) -> list[dict[str, Any]]:
    config_path = Path(settings.sources_config)
    if not config_path.exists() or not config_path.is_file():
        return []

    data = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    source_sets = data.get("source_sets", {})
    sources = source_sets.get(source_set, [])
    if not isinstance(sources, list):
        return []
    return [source for source in sources if isinstance(source, dict)]


def inspect_sources(settings: Settings, sources: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [inspect_source(settings, source) for source in sources]


def inspect_source(settings: Settings, source: dict[str, Any]) -> dict[str, Any]:
    source_id = str(source.get("id", "unknown"))
    source_type = str(source.get("type", "unknown"))

    if source_type == "url":
        return {
            "id": source_id,
            "type": source_type,
            "url": source.get("url"),
            "status": "skipped",
            "reason": "remote fetch not implemented",
        }

    if not source.get("enabled", True):
        return {
            "id": source_id,
            "type": source_type,
            "status": "skipped",
            "reason": "source disabled",
        }

    if source_type not in SUPPORTED_LOCAL_TYPES:
        return {
            "id": source_id,
            "type": source_type,
            "status": "skipped",
            "reason": "unsupported source type",
        }

    relative_path = str(source.get("path", ""))
    if not relative_path:
        return {
            "id": source_id,
            "type": source_type,
            "path": relative_path,
            "status": "skipped",
            "reason": "missing path",
        }

    safe_path = resolve_safe_path(settings.source_root, relative_path)
    if safe_path is None:
        return {
            "id": source_id,
            "type": source_type,
            "path": relative_path,
            "status": "skipped",
            "reason": "path outside source root or forbidden directory",
        }

    if not safe_path.exists() or not safe_path.is_file():
        return {
            "id": source_id,
            "type": source_type,
            "path": relative_path,
            "status": "skipped",
            "exists": False,
            "reason": "source file missing",
        }

    size = safe_path.stat().st_size
    if size > settings.max_file_bytes:
        return {
            "id": source_id,
            "type": source_type,
            "path": relative_path,
            "status": "skipped",
            "exists": True,
            "size": size,
            "reason": "file exceeds RESEARCH_MAX_FILE_BYTES",
        }

    text = safe_path.read_text(encoding="utf-8", errors="replace")
    return {
        "id": source_id,
        "type": source_type,
        "path": relative_path,
        "status": "processed",
        "exists": True,
        "size": size,
        "line_count": len(text.splitlines()),
        "first_heading": first_markdown_heading(text) if source_type == "local_markdown" else None,
    }


def resolve_safe_path(source_root: str, relative_path: str) -> Path | None:
    root = Path(source_root).resolve()
    raw_path = Path(relative_path)
    if raw_path.is_absolute():
        return None
    if any(part in SKIPPED_DIR_PARTS or part.startswith(".") for part in raw_path.parts):
        return None

    candidate = (root / raw_path).resolve()
    if not candidate.is_relative_to(root):
        return None
    return candidate


def first_markdown_heading(text: str) -> str | None:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("#"):
            return stripped.lstrip("#").strip() or None
    return None
