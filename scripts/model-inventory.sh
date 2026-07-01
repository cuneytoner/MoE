#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE_MODEL_ROOT="${ACTIVE_MODEL_ROOT:-/home/cuneyt/MoE_Models_Backup}"
ARCHIVE_MODEL_ROOT="${ARCHIVE_MODEL_ROOT:-/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive}"
OUTPUT="${MODEL_INVENTORY_OUTPUT:-/home/cuneyt/MoE/runtime/reports/models/model-inventory.json}"

case "$OUTPUT" in
  "$ROOT"|"$ROOT"/*)
    echo "FAIL: refusing to write model inventory inside codebase: $OUTPUT" >&2
    exit 1
    ;;
esac

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$ACTIVE_MODEL_ROOT" "$ARCHIVE_MODEL_ROOT" "$OUTPUT" <<'PY'
import json
import os
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

active_root = Path(sys.argv[1]).expanduser()
archive_root = Path(sys.argv[2]).expanduser()
output = Path(sys.argv[3]).expanduser()

def iso_from_mtime(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()

def model_kind(path: Path) -> str:
    if path.is_dir():
        return "directory"
    suffix = path.suffix.lower().lstrip(".")
    return suffix or "file"

def scan_root(root: Path, root_name: str) -> dict:
    entries = []
    root_exists = root.exists()
    if root_exists:
        for path in sorted(root.rglob("*")):
            try:
                stat = path.stat()
            except OSError as exc:
                entries.append({
                    "path": str(path),
                    "relative_path": str(path.relative_to(root)) if path.is_relative_to(root) else str(path),
                    "name": path.name,
                    "kind": "unreadable",
                    "status": "unreadable",
                    "detail": exc.__class__.__name__,
                })
                continue
            if path.is_file() or path.is_dir():
                entries.append({
                    "path": str(path),
                    "relative_path": str(path.relative_to(root)),
                    "name": path.name,
                    "kind": model_kind(path),
                    "is_file": path.is_file(),
                    "is_dir": path.is_dir(),
                    "size_bytes": stat.st_size if path.is_file() else None,
                    "modified_at": iso_from_mtime(path),
                })
    files = [entry for entry in entries if entry.get("is_file")]
    return {
        "root": str(root),
        "root_name": root_name,
        "exists": root_exists,
        "file_count": len(files),
        "directory_count": sum(1 for entry in entries if entry.get("is_dir")),
        "total_file_bytes": sum(entry.get("size_bytes") or 0 for entry in files),
        "entries": entries,
    }

active = scan_root(active_root, "active")
archive = scan_root(archive_root, "archive")

groups = defaultdict(list)
for root_name, scanned in (("active", active), ("archive", archive)):
    for entry in scanned["entries"]:
        if not entry.get("is_file"):
            continue
        key = (entry["name"].lower(), entry.get("size_bytes"))
        groups[key].append({
            "root": root_name,
            "path": entry["path"],
            "size_bytes": entry.get("size_bytes"),
        })

duplicates = [
    {
        "name": name,
        "size_bytes": size,
        "candidates": candidates,
    }
    for (name, size), candidates in sorted(groups.items())
    if len(candidates) > 1
]

report = {
    "status": "ok",
    "service": "model-inventory",
    "read_only": True,
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "active_root": str(active_root),
    "archive_root": str(archive_root),
    "output": str(output),
    "active": active,
    "archive": archive,
    "duplicate_candidates": duplicates,
    "summary": {
        "active_files": active["file_count"],
        "archive_files": archive["file_count"],
        "active_bytes": active["total_file_bytes"],
        "archive_bytes": archive["total_file_bytes"],
        "duplicate_candidate_groups": len(duplicates),
    },
}

output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"PASS: wrote model inventory report: {output}")
print(f"INFO: active files={active['file_count']} archive files={archive['file_count']} duplicate groups={len(duplicates)}")
PY
