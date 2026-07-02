from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
MEMORY_CANDIDATES_PATH = RUNTIME_ROOT / "reports/memory-candidates/feedback-memory-candidates.json"
MEMORY_STORE_DIR = RUNTIME_ROOT / "reports/memory-store"
MEMORY_STORE_PLAN_PATH = MEMORY_STORE_DIR / "memory-store-plan.json"
MEMORY_STORE_AUDIT_PATH = MEMORY_STORE_DIR / "memory-store-audit.json"
HELPER_REPORT_PATH = MEMORY_STORE_DIR / "memory-candidate-approval-helper-report.json"
APPLY_LOG_PATH = MEMORY_STORE_DIR / "memory-store-apply-log.jsonl"
APPLY_SUMMARY_PATH = MEMORY_STORE_DIR / "memory-store-apply-summary.json"
E2E_REPORT_PATH = MEMORY_STORE_DIR / "memory-approval-dry-run-e2e-report.json"
EXAMPLE_APPROVAL_FILE_PATH = MEMORY_STORE_DIR / "approved-memory-candidates.example.json"
APPROVAL_FILE_PATH = MEMORY_STORE_DIR / "approved-memory-candidates.json"

REPORT_PATHS = {
    "memory_candidates": MEMORY_CANDIDATES_PATH,
    "memory_store_plan": MEMORY_STORE_PLAN_PATH,
    "memory_store_audit": MEMORY_STORE_AUDIT_PATH,
    "approval_helper_report": HELPER_REPORT_PATH,
    "apply_log": APPLY_LOG_PATH,
    "apply_summary": APPLY_SUMMARY_PATH,
    "dry_run_e2e_report": E2E_REPORT_PATH,
    "example_approval_file": EXAMPLE_APPROVAL_FILE_PATH,
    "real_approval_file": APPROVAL_FILE_PATH,
}

SAFETY_BOUNDARIES = [
    "read-only endpoint",
    "no approval actions",
    "no Memory API writes",
    "no script execution",
    "no Docker control",
    "no model switching",
    "no raw prompts or responses",
    "no generated runtime reports committed to repo",
]


def build_memory_approval_dashboard() -> dict[str, Any]:
    loaded = {name: _load_report(path) for name, path in REPORT_PATHS.items()}
    warnings = _warnings(loaded)
    helper = loaded["approval_helper_report"]["data"]
    plan = loaded["memory_store_plan"]["data"]
    audit = loaded["memory_store_audit"]["data"]
    apply_summary = loaded["apply_summary"]["data"]
    e2e_report = loaded["dry_run_e2e_report"]["data"]
    approval_file = loaded["real_approval_file"]["data"]

    candidates = _candidate_cards(helper)
    duplicates = _duplicate_groups(audit, helper)
    apply_log = _apply_log_summary(loaded["apply_log"], loaded["apply_summary"])
    e2e = _e2e_summary(loaded["dry_run_e2e_report"], e2e_report)

    return {
        "service": "memory-approval-dashboard",
        "generated_at": _utc_now(),
        "read_only": True,
        "apply_supported": False,
        "approval_supported": False,
        "memory_write_supported": False,
        "human_review_required": True,
        "reports": {name: _report_metadata(item) for name, item in loaded.items()},
        "summary": _summary(
            helper=helper,
            plan=plan,
            audit=audit,
            apply_log=apply_log,
        ),
        "candidates": candidates,
        "duplicates": duplicates,
        "approval": _approval_summary(
            approval_report=loaded["real_approval_file"],
            example_report=loaded["example_approval_file"],
            approval_file=approval_file,
        ),
        "apply_log": apply_log,
        "e2e": e2e,
        "warnings": warnings,
        "safety_boundaries": SAFETY_BOUNDARIES,
    }


def _load_report(path: Path) -> dict[str, Any]:
    metadata = _file_metadata(path)
    if not path.exists():
        return {**metadata, "valid": False, "data": None, "detail": "missing"}
    if not path.is_file():
        return {**metadata, "valid": False, "data": None, "detail": "not a file"}
    if path.suffix == ".jsonl":
        return _load_jsonl_summary(path, metadata)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        return {**metadata, "valid": False, "data": None, "detail": exc.__class__.__name__}
    if not isinstance(data, dict):
        return {**metadata, "valid": False, "data": None, "detail": "expected JSON object"}
    return {**metadata, "valid": True, "data": data, "detail": "ok"}


def _load_jsonl_summary(path: Path, metadata: dict[str, Any]) -> dict[str, Any]:
    total = 0
    malformed = 0
    latest_attempt_at = None
    counts = {"stored": 0, "failed": 0, "skipped": 0, "dry_run": 0}
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                if not line.strip():
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    malformed += 1
                    continue
                if not isinstance(entry, dict):
                    malformed += 1
                    continue
                total += 1
                result = entry.get("result")
                mode = entry.get("mode")
                if result in {"stored", "failed", "skipped"}:
                    counts[result] += 1
                if mode == "dry_run":
                    counts["dry_run"] += 1
                if isinstance(entry.get("timestamp"), str):
                    latest_attempt_at = entry["timestamp"]
    except OSError as exc:
        return {**metadata, "valid": False, "data": None, "detail": exc.__class__.__name__}

    return {
        **metadata,
        "valid": True,
        "data": {
            "total_attempts": total,
            "malformed_count": malformed,
            "stored_count": counts["stored"],
            "failed_count": counts["failed"],
            "skipped_count": counts["skipped"],
            "dry_run_count": counts["dry_run"],
            "latest_attempt_at": latest_attempt_at,
        },
        "detail": "ok",
    }


def _file_metadata(path: Path) -> dict[str, Any]:
    exists = path.exists()
    metadata: dict[str, Any] = {
        "path": str(path),
        "exists": exists,
        "valid": False,
        "modified_at": None,
        "size_bytes": None,
    }
    if not exists:
        return metadata
    try:
        stat = path.stat()
    except OSError:
        return metadata
    metadata["modified_at"] = datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat().replace("+00:00", "Z")
    metadata["size_bytes"] = stat.st_size
    return metadata


def _report_metadata(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "path": report["path"],
        "exists": report["exists"],
        "valid": report["valid"],
        "modified_at": report.get("modified_at"),
        "size_bytes": report.get("size_bytes"),
    }


def _warnings(loaded: dict[str, dict[str, Any]]) -> list[str]:
    warnings = []
    for name, report in loaded.items():
        if not report["exists"]:
            warnings.append(f"{name} missing: {report['path']}")
        elif not report["valid"]:
            warnings.append(f"{name} invalid: {report.get('detail')}")
    return warnings


def _summary(
    *,
    helper: dict[str, Any] | None,
    plan: dict[str, Any] | None,
    audit: dict[str, Any] | None,
    apply_log: dict[str, Any],
) -> dict[str, Any]:
    helper_summary = helper.get("candidate_summary") if isinstance(helper, dict) else {}
    audit_counts = audit.get("counts") if isinstance(audit, dict) else {}
    return {
        "total_candidates": _int_from(helper_summary, "total_candidates"),
        "approved_count": _list_count(plan, "approved_candidates") if plan else _int_from(helper_summary, "approved_count"),
        "blocked_count": _list_count(plan, "blocked_candidates") if plan else _int_from(helper_summary, "blocked_count"),
        "duplicate_group_count": _int_from(audit_counts, "duplicate_group_count") or _int_from(helper_summary, "duplicate_group_count"),
        "duplicate_candidate_count": _int_from(audit_counts, "duplicate_candidate_count"),
        "dry_run_attempt_count": _int_value(apply_log.get("dry_run_count")),
        "stored_count": _int_value(apply_log.get("stored_count")),
        "failed_count": _int_value(apply_log.get("failed_count")),
        "skipped_count": _int_value(apply_log.get("skipped_count")),
    }


def _candidate_cards(helper: dict[str, Any] | None) -> list[dict[str, Any]]:
    cards = helper.get("candidate_cards") if isinstance(helper, dict) else []
    if not isinstance(cards, list):
        return []
    result = []
    for card in cards[:20]:
        if not isinstance(card, dict):
            continue
        result.append(
            {
                "id": _safe_text(card.get("id"), 128),
                "category": _safe_text(card.get("category"), 64),
                "risk": _safe_text(card.get("risk"), 32),
                "current_status": _safe_text(card.get("current_status"), 32),
                "duplicate_group_id": _safe_text(card.get("duplicate_group_id"), 80) or None,
                "title": _safe_text(card.get("title"), 160),
                "review_hint": _safe_text(card.get("review_hint"), 220),
            }
        )
    return result


def _duplicate_groups(audit: dict[str, Any] | None, helper: dict[str, Any] | None) -> list[dict[str, Any]]:
    groups = audit.get("duplicate_groups") if isinstance(audit, dict) else None
    if not isinstance(groups, list):
        duplicate_summary = helper.get("duplicate_summary") if isinstance(helper, dict) else {}
        groups = duplicate_summary.get("groups") if isinstance(duplicate_summary, dict) else []
    if not isinstance(groups, list):
        return []
    result = []
    for group in groups[:20]:
        if not isinstance(group, dict):
            continue
        candidate_ids = group.get("candidate_ids")
        if not isinstance(candidate_ids, list):
            candidate_ids = []
        result.append(
            {
                "group_id": _safe_text(group.get("group_id"), 80),
                "category": _safe_text(group.get("category"), 64),
                "normalized_title": _safe_text(group.get("normalized_title"), 160),
                "count": _int_value(group.get("count")),
                "candidate_ids": [_safe_text(item, 128) for item in candidate_ids[:10] if isinstance(item, str)],
                "recommended_action": _safe_text(group.get("recommended_action"), 80),
            }
        )
    return result


def _approval_summary(
    *,
    approval_report: dict[str, Any],
    example_report: dict[str, Any],
    approval_file: dict[str, Any] | None,
) -> dict[str, Any]:
    approved = approval_file.get("approved_candidate_ids") if isinstance(approval_file, dict) else None
    return {
        "real_approval_file_exists": bool(approval_report["exists"]),
        "example_approval_file_exists": bool(example_report["exists"]),
        "approval_file_path": str(APPROVAL_FILE_PATH),
        "example_approval_file_path": str(EXAMPLE_APPROVAL_FILE_PATH),
        "approved_candidate_ids_count": len(approved) if isinstance(approved, list) else 0,
    }


def _apply_log_summary(log_report: dict[str, Any], summary_report: dict[str, Any]) -> dict[str, Any]:
    data = summary_report["data"] if summary_report["valid"] else log_report["data"]
    if not isinstance(data, dict):
        data = {}
    return {
        "log_exists": bool(log_report["exists"]),
        "summary_exists": bool(summary_report["exists"]),
        "total_attempts": _int_from(data, "total_attempts"),
        "stored_count": _int_from(data, "stored_count"),
        "failed_count": _int_from(data, "failed_count"),
        "skipped_count": _int_from(data, "skipped_count"),
        "dry_run_count": _int_from(data, "dry_run_count"),
        "latest_attempt_at": data.get("latest_attempt_at"),
    }


def _e2e_summary(report: dict[str, Any], data: dict[str, Any] | None) -> dict[str, Any]:
    if not isinstance(data, dict):
        data = {}
    return {
        "report_exists": bool(report["exists"]),
        "e2e_status": data.get("e2e_status"),
        "dry_run_only": data.get("dry_run_only"),
        "apply_used": data.get("apply_used"),
        "test_approval_fixture_used": data.get("test_approval_fixture_used"),
        "test_approval_fixture_removed": data.get("test_approval_fixture_removed"),
    }


def _list_count(data: dict[str, Any] | None, key: str) -> int:
    if not isinstance(data, dict):
        return 0
    value = data.get(key)
    return len(value) if isinstance(value, list) else 0


def _int_from(data: Any, key: str) -> int:
    if not isinstance(data, dict):
        return 0
    return _int_value(data.get(key))


def _int_value(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def _safe_text(value: Any, limit: int) -> str:
    text = str(value or "")
    text = " ".join(text.split())
    return text[: limit - 3].rstrip() + "..." if len(text) > limit else text


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
