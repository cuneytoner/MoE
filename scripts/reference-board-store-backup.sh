#!/usr/bin/env bash
set -euo pipefail

REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"
BOARD_ID="${BOARD_ID:-}"
BACKUP_DIR="${BACKUP_DIR:-${REFERENCE_BOARD_RUNTIME_DIR}/backups}"
REPORT_PATH="${REPORT_PATH:-/tmp/moe-reference-board-store-backup-report.json}"

export REFERENCE_BOARD_RUNTIME_DIR BOARD_ID BACKUP_DIR REPORT_PATH

python3 - <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


BOARD_ID_MAX_LENGTH = 80
BOARD_ID_PATTERN = re.compile(r"^[a-z0-9_-]+$")

runtime_dir = Path(os.environ["REFERENCE_BOARD_RUNTIME_DIR"])
board_id = os.environ["BOARD_ID"].strip()
backup_dir = Path(os.environ["BACKUP_DIR"])
report_path = Path(os.environ["REPORT_PATH"])
created_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
timestamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")

findings: list[dict[str, str]] = []
source_file: Path | None = None
backup_file: Path | None = None
backup_created = False


def add_finding(severity: str, code: str, detail: str) -> None:
    findings.append({"severity": severity, "code": code, "detail": detail})


def write_report(exit_code: int) -> None:
    report = {
        "schema_version": "1.0",
        "report_type": "reference_board_store_backup",
        "created_at": created_at,
        "runtime_dir": str(runtime_dir),
        "board_id": board_id or None,
        "source_file": str(source_file) if source_file is not None else None,
        "backup_dir": str(backup_dir),
        "backup_file": str(backup_file) if backup_file is not None else None,
        "backup_created": backup_created,
        "findings": findings,
        "safety_flags": {
            "source_assets_modified": False,
            "board_file_modified": False,
            "backup_created": backup_created,
            "repair_applied": False,
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


if not board_id:
    add_finding("error", "missing_board_id", "BOARD_ID is required")
    print("Reference board store backup failed")
    write_report(2)

if not is_safe_board_id(board_id):
    add_finding("error", "invalid_board_id", "BOARD_ID must use lowercase letters, numbers, dash, or underscore only")
    print("Reference board store backup failed")
    write_report(2)

try:
    runtime_resolved = runtime_dir.resolve(strict=True)
except OSError:
    add_finding("error", "runtime_dir_missing", "reference board runtime directory is unavailable")
    print("Reference board store backup failed")
    write_report(2)

source_file = runtime_resolved / f"{board_id}.json"
if not source_file.is_file():
    add_finding("error", "source_board_missing", "source board file does not exist")
    print("Reference board store backup failed")
    write_report(3)

try:
    backup_parent = backup_dir.parent.resolve(strict=True)
except OSError:
    add_finding("error", "backup_parent_missing", "backup parent directory is unavailable")
    print("Reference board store backup failed")
    write_report(1)

expected_backup_parent = runtime_resolved
if backup_parent != expected_backup_parent:
    add_finding("error", "unsafe_backup_dir", "BACKUP_DIR must be a direct child of the reference board runtime directory")
    print("Reference board store backup failed")
    write_report(2)

if backup_dir.name != "backups":
    add_finding("error", "unsafe_backup_dir", "BACKUP_DIR must be named backups")
    print("Reference board store backup failed")
    write_report(2)

backup_dir.mkdir(mode=0o755, exist_ok=True)
backup_dir_resolved = backup_dir.resolve(strict=True)
try:
    backup_dir_resolved.relative_to(runtime_resolved)
except ValueError:
    add_finding("error", "unsafe_backup_dir", "BACKUP_DIR must stay under the reference board runtime directory")
    print("Reference board store backup failed")
    write_report(2)

backup_file = backup_dir_resolved / f"reference-board-{board_id}-{timestamp}.json.bak"
if backup_file.exists():
    add_finding("error", "backup_exists", "backup file already exists")
    print("Reference board store backup failed")
    write_report(1)

try:
    payload = source_file.read_bytes()
    with backup_file.open("xb") as handle:
        handle.write(payload)
    backup_created = True
except OSError:
    add_finding("error", "backup_failed", "backup file could not be written")
    print("Reference board store backup failed")
    write_report(1)

print("Reference board store backup OK")
print(f"BOARD_ID={board_id}")
print(f"BACKUP_FILE={backup_file}")
write_report(0)
PY
