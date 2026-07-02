#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_APPLY_LOG_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-apply-log.jsonl"
MEMORY_STORE_APPLY_SUMMARY_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-apply-summary.json"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" "$MEMORY_STORE_APPLY_LOG_PATH" "$MEMORY_STORE_APPLY_SUMMARY_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
log_path = sys.argv[2]
summary_path = sys.argv[3]
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_apply_log import apply_log_status

status = apply_log_status(log_path=log_path, summary_path=summary_path)
if not status["log_exists"]:
    print(f"SKIP: Memory store apply log does not exist: {status['log_path']}")
    print(f"Latest summary path: {status['summary_path']}")
    raise SystemExit(0)

print("Memory store apply log status")
print(f"  log_path: {status['log_path']}")
print(f"  total_attempts: {status['total_attempts']}")
print(f"  stored_count: {status['stored_count']}")
print(f"  failed_count: {status['failed_count']}")
print(f"  skipped_count: {status['skipped_count']}")
print(f"  dry_run_count: {status['dry_run_count']}")
print(f"  latest_attempt_at: {status['latest_attempt_at']}")
print(f"  summary_path: {status['summary_path']}")
print(f"  summary_exists: {str(status['summary_exists']).lower()}")
PY
