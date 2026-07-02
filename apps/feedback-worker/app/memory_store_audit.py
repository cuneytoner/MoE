import json
import re
import string
from collections import Counter, defaultdict
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "memory-store-audit"
AUDIT_STATUS = "review_required"


def read_optional_json(path: str | Path) -> dict[str, Any] | None:
    expanded = Path(path).expanduser()
    if not expanded.exists():
        return None
    return json.loads(expanded.read_text(encoding="utf-8"))


def build_memory_store_audit(
    *,
    source_plan_path: str,
    source_candidates_path: str,
    plan: dict[str, Any] | None,
    candidates_report: dict[str, Any] | None,
) -> dict[str, Any]:
    plan_candidates = _collect_plan_candidates(plan)
    candidate_lookup = _candidate_lookup(candidates_report)
    enriched = [_enrich_candidate(candidate, candidate_lookup) for candidate in plan_candidates]
    groups = _groups(enriched)
    duplicate_groups = [group for group in groups if group["count"] > 1]
    unique_groups = [group for group in groups if group["count"] == 1]
    approved = [item for item in enriched if item["state"] == "approved"]
    blocked = [item for item in enriched if item["state"] == "blocked"]
    pending = [item for item in enriched if item["state"] == "pending"]

    counts = {
        "approved_count": len(approved),
        "blocked_count": len(blocked),
        "pending_count": len(pending),
        "duplicate_group_count": len(duplicate_groups),
        "duplicate_candidate_count": sum(group["count"] for group in duplicate_groups),
        "unique_group_count": len(unique_groups),
    }

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_plan_path": source_plan_path,
        "source_candidates_path": source_candidates_path,
        "input_availability": {
            "memory_store_plan": plan is not None,
            "feedback_memory_candidates": candidates_report is not None,
        },
        "audit_status": AUDIT_STATUS,
        "memory_write_supported": False,
        "apply_supported": False,
        "human_review_required": True,
        "counts": counts,
        "duplicate_groups": duplicate_groups,
        "unique_candidate_groups": unique_groups,
        "approved_summary": _summary(approved),
        "blocked_summary": _summary(blocked),
        "pending_summary": _summary(pending),
        "recommendations": _recommendations(
            counts=counts,
            enriched=enriched,
            duplicate_groups=duplicate_groups,
        ),
        "validation_plan": _validation_plan(),
        "safety_boundaries": _safety_boundaries(),
        "reviewer_checklist": _reviewer_checklist(),
        "next_steps": _next_steps(),
    }


def write_memory_store_audit(path: str | Path, audit: dict[str, Any]) -> Path:
    expanded = Path(path).expanduser()
    expanded.parent.mkdir(parents=True, exist_ok=True)
    expanded.write_text(json.dumps(audit, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return expanded


def _collect_plan_candidates(plan: dict[str, Any] | None) -> list[dict[str, Any]]:
    if not plan:
        return []

    collected: list[dict[str, Any]] = []
    for state, field in (
        ("approved", "approved_candidates"),
        ("blocked", "blocked_candidates"),
        ("pending", "pending_candidates"),
    ):
        items = plan.get(field)
        if not isinstance(items, list):
            continue
        for item in items:
            if isinstance(item, dict):
                candidate = dict(item)
                candidate["state"] = state
                collected.append(candidate)
    return collected


def _candidate_lookup(candidates_report: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    if not candidates_report:
        return {}
    candidates = candidates_report.get("candidates")
    if not isinstance(candidates, list):
        return {}
    lookup = {}
    for item in candidates:
        if isinstance(item, dict) and isinstance(item.get("id"), str):
            lookup[item["id"]] = item
    return lookup


def _enrich_candidate(
    candidate: dict[str, Any],
    candidate_lookup: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    candidate_id = _safe_text(candidate.get("id"), limit=128)
    source = candidate_lookup.get(candidate_id, {})
    title = _safe_text(candidate.get("title") or source.get("title"), limit=160)
    category = _safe_text(candidate.get("category") or source.get("category"), limit=64)
    risk = _safe_text(candidate.get("risk") or source.get("risk"), limit=32)
    return {
        "id": candidate_id,
        "state": _safe_text(candidate.get("state"), limit=32),
        "category": category or "workflow",
        "title": title or "Untitled candidate",
        "risk": risk or "unknown",
    }


def _groups(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            _normalize(candidate["category"]),
            _normalize(candidate["title"]),
        )
        grouped[key].append(candidate)

    groups = []
    for index, ((category, title), items) in enumerate(sorted(grouped.items()), start=1):
        candidate_ids = sorted(item["id"] for item in items)
        titles = sorted({item["title"] for item in items})
        group = {
            "group_id": f"candidate-group-{index:03d}",
            "normalized_title": title,
            "category": category or "workflow",
            "count": len(items),
            "candidate_ids": candidate_ids,
            "titles": titles,
            "recommended_action": _recommended_action(items),
            "rationale": _group_rationale(items),
        }
        groups.append(group)
    return groups


def _recommended_action(items: list[dict[str, Any]]) -> str:
    if len(items) == 1:
        return "keep_separate"
    if any(item["risk"] == "high" for item in items):
        return "reject_duplicates"
    return "review_and_merge"


def _group_rationale(items: list[dict[str, Any]]) -> str:
    if len(items) == 1:
        return "This candidate group is unique after title and category normalization."
    return "Multiple candidates share the same normalized title and category; review before approval."


def _summary(items: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "count": len(items),
        "category_counts": dict(sorted(Counter(item["category"] for item in items).items())),
        "risk_counts": dict(sorted(Counter(item["risk"] for item in items).items())),
    }


def _recommendations(
    *,
    counts: dict[str, int],
    enriched: list[dict[str, Any]],
    duplicate_groups: list[dict[str, Any]],
) -> list[str]:
    recommendations = []
    if duplicate_groups:
        recommendations.append("Review and merge duplicate candidate groups before approving memory storage.")
    if counts["blocked_count"] > 0 and counts["approved_count"] == 0:
        recommendations.append("Create approved-memory-candidates.json only after reviewing blocked candidates.")
    if counts["approved_count"] == 0:
        recommendations.append("Keep Memory API writes disabled because no candidates are approved.")
    if counts["approved_count"] > 0:
        recommendations.append("Run the memory store workflow in dry-run mode before any APPLY=1 run.")
    if any(item["risk"] == "high" for item in enriched):
        recommendations.append("Reject or keep high-risk candidates blocked unless a reviewer explicitly approves them.")

    category_counts = Counter(item["category"] for item in enriched)
    docs_tests = category_counts.get("docs", 0) + category_counts.get("tests", 0)
    if enriched and docs_tests >= max(1, len(enriched) // 2):
        recommendations.append("Treat docs and tests candidates as improvement tasks unless they are stable long-term lessons.")

    if not recommendations:
        recommendations.append("No duplicate or approval issues were detected; keep human review before storage.")
    return recommendations


def _validation_plan() -> list[str]:
    return [
        "make check-layout",
        "make check-python-syntax",
        "make memory-store-audit-local",
        "make test-memory-store-audit",
        "make test-memory-store-workflow",
        "make test-feedback-memory-candidates",
        "make test",
    ]


def _safety_boundaries() -> list[str]:
    return [
        "no automatic memory writes",
        "no Memory API calls",
        "no raw prompts",
        "no raw responses",
        "no individual feedback records",
        "no auto-approval",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no training or fine-tuning",
        "no generated runtime report committed to repo",
    ]


def _reviewer_checklist() -> list[str]:
    return [
        "inspect duplicate groups",
        "merge or reject duplicates before approval",
        "approve only stable project-level lessons",
        "avoid storing docs/test todos as long-term memory unless truly useful",
        "confirm no runtime files are staged",
        "run validation commands",
    ]


def _next_steps() -> list[str]:
    return [
        "Review duplicate groups and decide whether to merge, separate, or reject them.",
        "Edit approved-memory-candidates.json only after human review.",
        "Regenerate the memory store plan after approval changes.",
        "Keep Memory API writes disabled until a separate APPLY=1 store run is intentionally requested.",
        "Generate a future memory store apply log after any approved storage run.",
    ]


def _normalize(value: str) -> str:
    value = value.lower().strip()
    value = value.translate(str.maketrans("", "", string.punctuation))
    return re.sub(r"\s+", " ", value).strip()


def _safe_text(value: object, *, limit: int) -> str:
    text = str(value or "")
    text = re.sub(r"(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*\S+", "[redacted]", text)
    text = re.sub(r"[\r\n\t]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    for marker in ("raw prompt", "raw response", "model response", "feedback record"):
        text = re.sub(re.escape(marker), "review content", text, flags=re.IGNORECASE)
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
