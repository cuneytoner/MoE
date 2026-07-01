#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY_CONFIG="${MODEL_REGISTRY_CONFIG:-$ROOT/configs/model-registry.example.yaml}"
ACTIVE_MODEL_ROOT="${ACTIVE_MODEL_ROOT:-/home/cuneyt/MoE_Models_Backup}"
ARCHIVE_MODEL_ROOT="${ARCHIVE_MODEL_ROOT:-/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive}"
OUTPUT_ROOT="/home/cuneyt/MoE/runtime/reports/models"
OUTPUT="${MODEL_INVENTORY_OUTPUT:-$OUTPUT_ROOT/model-inventory.json}"

case "$OUTPUT" in
  "$OUTPUT_ROOT"|"$OUTPUT_ROOT"/*)
    ;;
  *)
    echo "FAIL: model inventory output must stay under $OUTPUT_ROOT: $OUTPUT" >&2
    exit 1
    ;;
esac

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$ACTIVE_MODEL_ROOT" "$ARCHIVE_MODEL_ROOT" "$OUTPUT" "$REGISTRY_CONFIG" <<'PY'
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

active_root = Path(sys.argv[1]).expanduser()
archive_root = Path(sys.argv[2]).expanduser()
output = Path(sys.argv[3]).expanduser()
registry_config = Path(sys.argv[4]).expanduser()


def parse_registry(path: Path) -> dict:
    registry = {
        "required_active": [],
        "optional_duplicate_candidates": [],
        "archived_optional": [],
    }
    section = None
    current = None
    if not path.exists():
        return registry

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not raw_line.startswith(" ") and stripped.endswith(":"):
            if section in registry and current:
                registry[section].append(current)
            section = stripped[:-1]
            current = None
            continue
        if section not in registry:
            continue
        if stripped.startswith("- id:"):
            if current:
                registry[section].append(current)
            current = {"id": stripped.split(":", 1)[1].strip()}
            continue
        if current is not None and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = value.strip()

    if section in registry and current:
        registry[section].append(current)
    return registry


def iso_from_mtime(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()


def model_kind(path: Path) -> str:
    if path.is_dir():
        return "directory"
    suffix = path.suffix.lower().lstrip(".")
    return suffix or "file"


def is_generic_duplicate_artifact(entry: dict) -> bool:
    if not entry.get("is_file"):
        return False
    path = entry.get("path", "")
    normalized = path.replace("\\", "/")
    if "/.git/" in normalized or "/.cache/" in normalized:
        return False
    suffix = Path(path).suffix.lower()
    return suffix in {".gguf", ".safetensors", ".bin", ".pt", ".pth", ".onnx"}


def scan_root(root: Path, root_name: str) -> tuple[list[dict], int]:
    entries = []
    total_bytes = 0
    if not root.exists():
        return entries, total_bytes

    for path in sorted(root.rglob("*")):
        try:
            stat = path.stat()
        except OSError as exc:
            entries.append({
                "root": root_name,
                "path": str(path),
                "relative_path": str(path.relative_to(root)) if path.is_relative_to(root) else str(path),
                "name": path.name,
                "kind": "unreadable",
                "exists": False,
                "detail": exc.__class__.__name__,
            })
            continue

        if not path.is_file() and not path.is_dir():
            continue

        size_bytes = stat.st_size if path.is_file() else None
        if size_bytes is not None:
            total_bytes += size_bytes
        entries.append({
            "root": root_name,
            "path": str(path),
            "relative_path": str(path.relative_to(root)),
            "name": path.name,
            "kind": model_kind(path),
            "exists": True,
            "is_file": path.is_file(),
            "is_dir": path.is_dir(),
            "size_bytes": size_bytes,
            "modified_at": iso_from_mtime(path),
        })

    return entries, total_bytes


def enrich(entries: list[dict], registry_by_path: dict, required: bool) -> list[dict]:
    enriched = []
    for entry in entries:
        item = dict(entry)
        registry_item = registry_by_path.get(item.get("path"))
        if registry_item:
            item["registry_id"] = registry_item.get("id")
            item["registry_type"] = registry_item.get("type")
            item["role"] = registry_item.get("role")
        item["required"] = bool(registry_item and required)
        enriched.append(item)
    return enriched


registry = parse_registry(registry_config)
active_entries, total_active_size = scan_root(active_root, "active")
archive_entries, total_archive_size = scan_root(archive_root, "archive")

required_by_path = {
    item.get("path"): item
    for item in registry["required_active"]
    if item.get("path")
}
archived_by_path = {
    item.get("archive_path"): item
    for item in registry["archived_optional"]
    if item.get("archive_path")
}

groups = defaultdict(list)
for entry in active_entries + archive_entries:
    if not is_generic_duplicate_artifact(entry):
        continue
    key = (entry["name"].lower(), entry.get("size_bytes"))
    groups[key].append({
        "root": entry["root"],
        "path": entry["path"],
        "size_bytes": entry.get("size_bytes"),
    })

duplicate_candidates = [
    {
        "name": name,
        "size_bytes": size,
        "configured": False,
        "candidates": candidates,
    }
    for (name, size), candidates in sorted(groups.items())
    if len(candidates) > 1
]

for item in registry["optional_duplicate_candidates"]:
    candidates = []
    for key, label in (("path", "candidate"), ("canonical_path", "canonical")):
        item_path = item.get(key)
        if not item_path:
            continue
        path = Path(item_path)
        candidate = {
            "root": "active",
            "path": item_path,
            "role": label,
            "exists": path.exists(),
        }
        if path.is_file():
            candidate["size_bytes"] = path.stat().st_size
        candidates.append(candidate)
    duplicate_candidates.append({
        "name": item.get("id"),
        "configured": True,
        "detail": item.get("role"),
        "candidates": candidates,
    })

missing_required = []
for item in registry["required_active"]:
    item_path = item.get("path")
    item_type = item.get("type")
    if not item_path:
        continue
    path = Path(item_path)
    exists = path.is_dir() if item_type == "directory" else path.is_file()
    if not exists:
        missing_required.append({
            "id": item.get("id"),
            "type": item_type,
            "path": item_path,
            "role": item.get("role"),
        })

report = {
    "status": "ok" if not missing_required else "missing_required",
    "service": "model-inventory",
    "read_only": True,
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "active_root": str(active_root),
    "archive_root": str(archive_root),
    "total_active_size_bytes": total_active_size,
    "total_archive_size_bytes": total_archive_size,
    "active_models": enrich(active_entries, required_by_path, True),
    "archived_models": enrich(archive_entries, archived_by_path, False),
    "duplicate_candidates": duplicate_candidates,
    "missing_required": missing_required,
}

output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"PASS: wrote model inventory report: {output}")
print(
    "INFO: active entries="
    f"{len(active_entries)} archive entries={len(archive_entries)} "
    f"duplicate groups={len(duplicate_candidates)} missing required={len(missing_required)}"
)
PY
