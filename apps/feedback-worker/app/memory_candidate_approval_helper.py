import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "memory-candidate-approval-helper"
HELPER_STATUS = "review_required"
SAFE_PREVIEW_LIMIT = 180


def read_optional_json(path: str | Path) -> dict[str, Any] | None:
    expanded = Path(path).expanduser()
    if not expanded.exists():
        return None
    return json.loads(expanded.read_text(encoding="utf-8"))


def write_json(path: str | Path, data: dict[str, Any]) -> Path:
    expanded = Path(path).expanduser()
    expanded.parent.mkdir(parents=True, exist_ok=True)
    expanded.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return expanded


def build_approval_helper_report(
    *,
    input_paths: dict[str, str],
    inputs: dict[str, dict[str, Any] | None],
    approval_file_path: str,
    example_approval_file_path: str,
) -> dict[str, Any]:
    candidates = _candidate_records(inputs)
    duplicate_lookup = _duplicate_lookup(inputs.get("memory_store_audit"))
    cards = [_candidate_card(candidate, duplicate_lookup) for candidate in candidates]
    blocked_or_risky = [
        _blocked_card(card)
        for card in cards
        if _is_blocked_or_risky(card)
    ]

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "input_paths": input_paths,
        "input_availability": {name: value is not None for name, value in inputs.items()},
        "approval_file_path": approval_file_path,
        "example_approval_file_path": example_approval_file_path,
        "helper_status": HELPER_STATUS,
        "auto_approval_supported": False,
        "memory_write_supported": False,
        "human_review_required": True,
        "candidate_summary": _candidate_summary(inputs, cards),
        "duplicate_summary": _duplicate_summary(inputs.get("memory_store_audit")),
        "recommended_review_order": _review_order(cards),
        "candidate_cards": cards,
        "blocked_or_risky_candidates": blocked_or_risky,
        "approval_instructions": _approval_instructions(),
        "validation_plan": _validation_plan(),
        "safety_boundaries": _safety_boundaries(),
        "next_steps": _next_steps(),
    }


def build_example_approval_file() -> dict[str, Any]:
    return {
        "approved_candidate_ids": [],
        "notes": "Copy this file to approved-memory-candidates.json and add reviewed candidate ids manually.",
    }


def list_rows_from_report(report: dict[str, Any]) -> list[dict[str, str]]:
    cards = report.get("candidate_cards")
    if not isinstance(cards, list):
        return []
    rows = []
    for card in cards:
        if not isinstance(card, dict):
            continue
        rows.append(
            {
                "id": _safe_text(card.get("id"), limit=34),
                "category": _safe_text(card.get("category"), limit=12),
                "risk": _safe_text(card.get("risk"), limit=10),
                "status": _safe_text(card.get("current_status"), limit=12),
                "duplicate": "yes" if card.get("duplicate_group_id") else "no",
                "title": _safe_text(card.get("title"), limit=72),
            }
        )
    return rows


def list_rows_from_candidates(candidates_report: dict[str, Any]) -> list[dict[str, str]]:
    candidates = candidates_report.get("candidates")
    if not isinstance(candidates, list):
        return []
    rows = []
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        rows.append(
            {
                "id": _safe_text(candidate.get("id"), limit=34),
                "category": _safe_text(candidate.get("category"), limit=12),
                "risk": _safe_text(candidate.get("risk"), limit=10),
                "status": "pending",
                "duplicate": "unknown",
                "title": _safe_text(candidate.get("title"), limit=72),
            }
        )
    return rows


def _candidate_records(inputs: dict[str, dict[str, Any] | None]) -> list[dict[str, Any]]:
    candidates_report = inputs.get("feedback_memory_candidates")
    lookup: dict[str, dict[str, Any]] = {}
    if candidates_report and isinstance(candidates_report.get("candidates"), list):
        for item in candidates_report["candidates"]:
            if isinstance(item, dict):
                candidate_id = _safe_text(item.get("id"), limit=128)
                lookup[candidate_id] = dict(item)

    plan = inputs.get("memory_store_plan")
    if plan:
        for status, field in (
            ("approved", "approved_candidates"),
            ("blocked", "blocked_candidates"),
            ("pending", "pending_candidates"),
        ):
            items = plan.get(field)
            if not isinstance(items, list):
                continue
            for item in items:
                if not isinstance(item, dict):
                    continue
                candidate_id = _safe_text(item.get("id"), limit=128)
                merged = dict(lookup.get(candidate_id, {}))
                merged.update(item)
                merged["current_status"] = status
                lookup[candidate_id] = merged

    return [lookup[key] for key in sorted(lookup)]


def _candidate_card(
    candidate: dict[str, Any],
    duplicate_lookup: dict[str, str],
) -> dict[str, Any]:
    candidate_id = _safe_text(candidate.get("id"), limit=128)
    category = _safe_text(candidate.get("category"), limit=64) or "workflow"
    title = _safe_text(candidate.get("title"), limit=160)
    risk = _safe_text(candidate.get("risk"), limit=32) or "unknown"
    status = _safe_text(candidate.get("current_status"), limit=32) or "pending"
    duplicate_group_id = duplicate_lookup.get(candidate_id)
    return {
        "id": candidate_id,
        "category": category,
        "title": title,
        "confidence": candidate.get("confidence"),
        "risk": risk,
        "duplicate_group_id": duplicate_group_id,
        "current_status": status if status in {"pending", "blocked", "approved", "unknown"} else "unknown",
        "review_hint": _review_hint(
            candidate_id=candidate_id,
            category=category,
            title=title,
            risk=risk,
            duplicate_group_id=duplicate_group_id,
            proposed_memory_text=candidate.get("proposed_memory_text"),
        ),
        "proposed_memory_text_preview": _preview(candidate.get("proposed_memory_text")),
    }


def _candidate_summary(
    inputs: dict[str, dict[str, Any] | None],
    cards: list[dict[str, Any]],
) -> dict[str, Any]:
    plan = inputs.get("memory_store_plan")
    audit = inputs.get("memory_store_audit")
    counts = audit.get("counts") if isinstance(audit, dict) else None
    return {
        "total_candidates": len(cards),
        "approved_count": _list_count(plan, "approved_candidates"),
        "blocked_count": _list_count(plan, "blocked_candidates"),
        "duplicate_group_count": _safe_int(counts.get("duplicate_group_count") if isinstance(counts, dict) else None),
    }


def _duplicate_summary(audit: dict[str, Any] | None) -> dict[str, Any]:
    counts = audit.get("counts") if isinstance(audit, dict) else None
    duplicate_groups = audit.get("duplicate_groups") if isinstance(audit, dict) else None
    return {
        "duplicate_group_count": _safe_int(counts.get("duplicate_group_count") if isinstance(counts, dict) else None),
        "duplicate_candidate_count": _safe_int(counts.get("duplicate_candidate_count") if isinstance(counts, dict) else None),
        "groups": duplicate_groups if isinstance(duplicate_groups, list) else [],
    }


def _duplicate_lookup(audit: dict[str, Any] | None) -> dict[str, str]:
    if not audit:
        return {}
    lookup = {}
    groups = audit.get("duplicate_groups")
    if not isinstance(groups, list):
        return lookup
    for group in groups:
        if not isinstance(group, dict):
            continue
        group_id = _safe_text(group.get("group_id"), limit=80)
        ids = group.get("candidate_ids")
        if not isinstance(ids, list):
            continue
        for candidate_id in ids:
            if isinstance(candidate_id, str) and candidate_id.strip():
                lookup[candidate_id] = group_id
    return lookup


def _review_order(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ordered = sorted(cards, key=_review_priority)
    return [
        {
            "candidate_id": card["id"],
            "title": card["title"],
            "category": card["category"],
            "risk": card["risk"],
            "duplicate_group_id": card.get("duplicate_group_id"),
            "review_hint": card["review_hint"],
        }
        for card in ordered
    ]


def _review_priority(card: dict[str, Any]) -> tuple[int, str, str]:
    risk = card.get("risk")
    category = card.get("category")
    duplicate = bool(card.get("duplicate_group_id"))
    missing_text = not bool(card.get("proposed_memory_text_preview"))
    if risk == "high" or missing_text:
        bucket = 4
    elif duplicate:
        bucket = 3
    elif category in {"docs", "tests"}:
        bucket = 2
    elif category in {"workflow", "routing", "model"} and risk in {"low", "unknown"}:
        bucket = 0
    else:
        bucket = 1
    return (bucket, str(category), str(card.get("title")))


def _blocked_card(card: dict[str, Any]) -> dict[str, Any]:
    reasons = []
    if card.get("risk") == "high":
        reasons.append("high risk")
    if card.get("duplicate_group_id"):
        reasons.append("duplicate candidate group")
    if not card.get("id"):
        reasons.append("missing id")
    if _vague(card.get("title")):
        reasons.append("vague title")
    if not card.get("proposed_memory_text_preview"):
        reasons.append("missing proposed memory text")
    return {
        "id": card.get("id"),
        "title": card.get("title"),
        "category": card.get("category"),
        "risk": card.get("risk"),
        "duplicate_group_id": card.get("duplicate_group_id"),
        "review_reasons": reasons,
    }


def _is_blocked_or_risky(card: dict[str, Any]) -> bool:
    return bool(_blocked_card(card)["review_reasons"])


def _review_hint(
    *,
    candidate_id: str,
    category: str,
    title: str,
    risk: str,
    duplicate_group_id: str | None,
    proposed_memory_text: object,
) -> str:
    if not candidate_id:
        return "Reject or repair before approval because the candidate has no stable id."
    if risk == "high":
        return "Keep blocked unless a reviewer confirms this is safe long-term memory."
    if duplicate_group_id:
        return f"Review duplicate group {duplicate_group_id} before approving this candidate."
    if _vague(title):
        return "Clarify the title before approval."
    if not _preview(proposed_memory_text):
        return "Reject until proposed memory text is present and sanitized."
    if category in {"workflow", "routing", "model"} and risk in {"low", "unknown"}:
        return "Good first-pass review candidate if the text is stable and project-level."
    if category in {"docs", "tests"}:
        return "Approve only if this is a durable lesson, not a short-lived task."
    return "Review manually before adding the id to the approval file."


def _approval_instructions() -> list[str]:
    return [
        "Inspect memory-candidate-approval-helper-report.json.",
        "Choose candidate ids manually after review.",
        "Copy approved-memory-candidates.example.json to approved-memory-candidates.json.",
        "Edit approved_candidate_ids manually; do not approve duplicates or risky candidates blindly.",
        "Run make memory-store-plan-local.",
        "Inspect /home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json.",
        "Run make memory-store-approved for dry-run.",
        "Only then optionally run APPLY=1 make memory-store-approved.",
    ]


def _validation_plan() -> list[str]:
    return [
        "make check-layout",
        "make check-python-syntax",
        "make memory-candidate-approval-helper-local",
        "make test-memory-candidate-approval-helper",
        "make memory-store-plan-local",
        "make memory-store-approved",
        "make test-memory-store-workflow",
        "make test",
    ]


def _safety_boundaries() -> list[str]:
    return [
        "no automatic approval",
        "no automatic memory writes",
        "no Memory API calls",
        "no raw prompts",
        "no raw responses",
        "no individual feedback records",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no training or fine-tuning",
        "no generated runtime report committed to repo",
    ]


def _next_steps() -> list[str]:
    return [
        "Review the recommended order and candidate cards.",
        "Create the real approval file manually only after review.",
        "Regenerate the memory store plan after editing approvals.",
        "Run the approved store workflow in dry-run mode first.",
        "Use APPLY=1 only as a separate explicit human-run step.",
    ]


def _list_count(value: dict[str, Any] | None, key: str) -> int:
    if not value:
        return 0
    items = value.get(key)
    return len(items) if isinstance(items, list) else 0


def _safe_int(value: object) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def _preview(value: object) -> str:
    text = _safe_text(value, limit=SAFE_PREVIEW_LIMIT)
    forbidden_patterns = (
        r"(?i)\braw\s+prompt\b.*",
        r"(?i)\braw\s+response\b.*",
        r"(?i)\bmodel\s+response\b.*",
        r"(?i)\bfeedback\s+record\b.*",
    )
    for pattern in forbidden_patterns:
        text = re.sub(pattern, "[redacted review content]", text)
    return text


def _safe_text(value: object, *, limit: int) -> str:
    text = str(value or "")
    text = re.sub(r"(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*\S+", "[redacted]", text)
    text = re.sub(r"[\r\n\t]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text


def _vague(value: object) -> bool:
    title = _safe_text(value, limit=160).lower()
    return not title or title in {"todo", "misc", "update", "fix", "review", "candidate"}


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
