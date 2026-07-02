import json
from collections import Counter
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


LOG_SERVICE = "human-approved-memory-store"
SUMMARY_SERVICE = "memory-store-apply-summary"


def append_apply_log(path: str | Path, entry: dict[str, Any]) -> Path:
    expanded = Path(path).expanduser()
    expanded.parent.mkdir(parents=True, exist_ok=True)
    with expanded.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, sort_keys=True, separators=(",", ":")))
        handle.write("\n")
    return expanded


def build_log_entry(
    *,
    mode: str,
    candidate: dict[str, Any],
    memory_api_url: str,
    result: str,
    request_supported: bool,
    apply_requested: bool,
    http_status: int | None = None,
    memory_id: str | None = None,
    error_summary: str | None = None,
) -> dict[str, Any]:
    return {
        "timestamp": _utc_now(),
        "service": LOG_SERVICE,
        "mode": mode,
        "candidate_id": _safe_text(candidate.get("id"), limit=128),
        "candidate_title": _safe_text(candidate.get("title"), limit=160),
        "category": _safe_text(candidate.get("category"), limit=64),
        "memory_api_url": memory_api_url.rstrip("/"),
        "request_supported": request_supported,
        "result": result,
        "http_status": http_status,
        "memory_id": memory_id,
        "error_summary": _safe_text(error_summary, limit=240) if error_summary else None,
        "raw_prompt_included": False,
        "raw_response_included": False,
        "human_approval_required": True,
        "apply_requested": apply_requested,
    }


def write_apply_summary(
    *,
    log_path: str | Path,
    summary_path: str | Path,
    memory_write_supported: bool,
) -> dict[str, Any]:
    expanded_log = Path(log_path).expanduser()
    entries = _read_entries(expanded_log)
    counts = Counter(entry.get("result") for entry in entries)
    mode_counts = Counter(entry.get("mode") for entry in entries)
    latest_attempt_at = None
    if entries:
        latest_attempt_at = entries[-1].get("timestamp")

    summary = {
        "generated_at": _utc_now(),
        "service": SUMMARY_SERVICE,
        "source_log_path": str(expanded_log),
        "total_attempts": len(entries),
        "stored_count": int(counts.get("stored", 0)),
        "failed_count": int(counts.get("failed", 0)),
        "skipped_count": int(counts.get("skipped", 0)),
        "dry_run_count": int(mode_counts.get("dry_run", 0)),
        "candidate_ids": sorted(
            {
                str(entry.get("candidate_id"))
                for entry in entries
                if isinstance(entry.get("candidate_id"), str)
            }
        ),
        "latest_attempt_at": latest_attempt_at,
        "memory_write_supported": memory_write_supported,
        "human_review_required": True,
        "raw_prompt_included": False,
        "raw_response_included": False,
    }
    expanded_summary = Path(summary_path).expanduser()
    expanded_summary.parent.mkdir(parents=True, exist_ok=True)
    expanded_summary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return summary


def apply_log_status(log_path: str | Path, summary_path: str | Path) -> dict[str, Any]:
    expanded_log = Path(log_path).expanduser()
    entries = _read_entries(expanded_log)
    counts = Counter(entry.get("result") for entry in entries)
    mode_counts = Counter(entry.get("mode") for entry in entries)
    latest_attempt_at = entries[-1].get("timestamp") if entries else None
    expanded_summary = Path(summary_path).expanduser()
    return {
        "log_path": str(expanded_log),
        "log_exists": expanded_log.exists(),
        "summary_path": str(expanded_summary),
        "summary_exists": expanded_summary.exists(),
        "total_attempts": len(entries),
        "stored_count": int(counts.get("stored", 0)),
        "failed_count": int(counts.get("failed", 0)),
        "skipped_count": int(counts.get("skipped", 0)),
        "dry_run_count": int(mode_counts.get("dry_run", 0)),
        "latest_attempt_at": latest_attempt_at,
    }


def _read_entries(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    entries: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(entry, dict):
                entries.append(entry)
    return entries


def _safe_text(value: object, *, limit: int) -> str:
    text = str(value or "")
    text = " ".join(text.split())
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
