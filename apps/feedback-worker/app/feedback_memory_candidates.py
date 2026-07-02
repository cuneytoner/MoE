import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "feedback-memory-candidate-review"
CANDIDATE_STATUS = "pending_human_review"
CATEGORIES = {"workflow", "routing", "model", "memory", "docs", "tests", "ops"}


def read_optional_json(path: str | Path) -> dict[str, Any] | None:
    expanded = Path(path).expanduser()
    if not expanded.exists():
        return None
    return json.loads(expanded.read_text(encoding="utf-8"))


def build_feedback_memory_candidates(
    *,
    input_paths: dict[str, str],
    inputs: dict[str, dict[str, Any] | None],
) -> dict[str, Any]:
    availability = {name: value is not None for name, value in inputs.items()}
    candidates = _candidates(inputs)
    rejected = _rejected_or_blocked(inputs, candidates)

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "input_paths": input_paths,
        "input_availability": availability,
        "candidate_status": CANDIDATE_STATUS,
        "memory_write_supported": False,
        "human_review_required": True,
        "candidates": candidates,
        "rejected_or_blocked_candidates": rejected,
        "validation_plan": _validation_plan(),
        "safety_boundaries": _safety_boundaries(),
        "reviewer_checklist": _reviewer_checklist(),
        "next_steps": _next_steps(),
    }


def write_feedback_memory_candidates(path: str | Path, report: dict[str, Any]) -> Path:
    expanded = Path(path).expanduser()
    expanded.parent.mkdir(parents=True, exist_ok=True)
    expanded.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return expanded


def _candidates(inputs: dict[str, dict[str, Any] | None]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []

    summary = inputs.get("feedback_summary")
    if summary:
        candidates.extend(_summary_candidates(summary))

    learning_report = inputs.get("learning_loop_report")
    if learning_report:
        candidates.extend(_learning_candidates(learning_report))

    improvement_plan = inputs.get("improvement_plan")
    if improvement_plan:
        candidates.extend(_improvement_candidates(improvement_plan))

    approval_packet = inputs.get("router_prompt_approval")
    if approval_packet:
        candidates.extend(_approval_candidates(approval_packet))

    if not candidates:
        candidates.append(
            _candidate(
                index=1,
                category="workflow",
                title="Continue gathering aggregate feedback before storing memory",
                proposed_memory_text="No stable feedback lesson is ready for memory storage yet; continue collecting aggregate Gateway feedback.",
                rationale="Available reports did not provide enough aggregate signal for a stable project-level lesson.",
                source_reports=_available_sources(inputs),
                confidence=0.35,
                risk="low",
            )
        )

    return _renumber(_dedupe_candidates(candidates))


def _summary_candidates(summary: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    record_count = _safe_int(summary.get("record_count"))
    ratings = _dict_of_ints(summary.get("rating_counts"))
    intents = _dict_of_ints(summary.get("router_intent_counts"))
    models = _dict_of_ints(summary.get("model_counts"))
    top_tags = _top_tags(summary.get("top_tags"))

    positive = ratings.get("accepted", 0) + ratings.get("useful", 0)
    negative = ratings.get("rejected", 0) + ratings.get("not_useful", 0)

    if record_count > 0:
        candidates.append(
            _candidate(
                index=1,
                category="workflow",
                title="Use aggregate feedback before changing behavior",
                proposed_memory_text=(
                    f"Gateway feedback review should rely on aggregate counts first; current summary has {record_count} records."
                ),
                rationale="The feedback summary is aggregate-only and suitable for a stable workflow reminder.",
                source_reports=["feedback_summary"],
                confidence=_confidence(record_count, 0.55),
                risk="low",
            )
        )

    if positive >= max(2, negative + 1):
        candidates.append(
            _candidate(
                index=2,
                category="tests",
                title="Preserve useful Gateway behavior with regression checks",
                proposed_memory_text="When useful feedback dominates, prefer regression tests and docs before changing router or prompt behavior.",
                rationale="Positive aggregate ratings exceed rejected or not-useful ratings.",
                source_reports=["feedback_summary"],
                confidence=_confidence(record_count, 0.62),
                risk="low",
            )
        )

    dominant_intent = _dominant(intents, record_count)
    if dominant_intent:
        candidates.append(
            _candidate(
                index=3,
                category="routing",
                title=f"Review repeated router intent {dominant_intent[0]}",
                proposed_memory_text=(
                    f"Router intent '{_clean_fragment(dominant_intent[0])}' appears repeatedly in aggregate feedback; review examples before router changes."
                ),
                rationale="One router intent dominates aggregate feedback counts.",
                source_reports=["feedback_summary"],
                confidence=_confidence(record_count, 0.68),
                risk="medium",
            )
        )

    dominant_model = _dominant(models, record_count, ratio=0.75)
    if dominant_model:
        candidates.append(
            _candidate(
                index=4,
                category="model",
                title=f"Review model routing alignment for {dominant_model[0]}",
                proposed_memory_text=(
                    f"Model '{_clean_fragment(dominant_model[0])}' dominates aggregate feedback; compare intended routing before any model changes."
                ),
                rationale="One model dominates aggregate model counts.",
                source_reports=["feedback_summary"],
                confidence=_confidence(record_count, 0.64),
                risk="medium",
            )
        )

    tag_names = [_clean_fragment(item["tag"]) for item in top_tags[:3]]
    if tag_names:
        candidates.append(
            _candidate(
                index=5,
                category="docs",
                title="Track repeated aggregate feedback tags",
                proposed_memory_text=f"Repeated aggregate feedback tags to review: {', '.join(tag_names)}.",
                rationale="Top tags are aggregate counts, not raw feedback bodies.",
                source_reports=["feedback_summary"],
                confidence=_confidence(record_count, 0.58),
                risk="low",
            )
        )

    return candidates


def _learning_candidates(report: dict[str, Any]) -> list[dict[str, Any]]:
    candidates = []
    for item in _dict_list(report.get("recommendations")):
        category = _map_category(item.get("category"))
        title = _safe_text(item.get("title"), default="Review aggregate learning recommendation")
        candidates.append(
            _candidate(
                index=len(candidates) + 1,
                category=category,
                title=title,
                proposed_memory_text=f"Learning loop recommendation for {category}: {_short_title(title)}.",
                rationale="The learning-loop report contains aggregate recommendations only.",
                source_reports=["learning_loop_report"],
                confidence=0.62,
                risk=_risk(category),
            )
        )
    return candidates


def _improvement_candidates(plan: dict[str, Any]) -> list[dict[str, Any]]:
    candidates = []
    for item in _dict_list(plan.get("proposed_changes")):
        category = _map_category(item.get("category"))
        if category == "memory":
            continue
        title = _safe_text(item.get("title"), default="Review proposed improvement")
        candidates.append(
            _candidate(
                index=len(candidates) + 1,
                category=category,
                title=title,
                proposed_memory_text=f"Improvement planning lesson for {category}: {_short_title(title)}.",
                rationale="The improvement plan is human-review-only and aggregate-derived.",
                source_reports=["improvement_plan"],
                confidence=0.56,
                risk=_risk(category),
            )
        )
    return candidates


def _approval_candidates(packet: dict[str, Any]) -> list[dict[str, Any]]:
    candidates = []
    for item in _dict_list(packet.get("approval_items")):
        category = _map_category(item.get("category"))
        title = _safe_text(item.get("title"), default="Review approval item")
        candidates.append(
            _candidate(
                index=len(candidates) + 1,
                category=category,
                title=title,
                proposed_memory_text=f"Approval workflow lesson for {category}: {_short_title(title)} requires explicit human review.",
                rationale="The approval packet marks this item as pending human review and not auto-applied.",
                source_reports=["router_prompt_approval"],
                confidence=0.52,
                risk=_risk(category),
            )
        )
    return candidates


def _rejected_or_blocked(
    inputs: dict[str, dict[str, Any] | None],
    candidates: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    rejected = []
    missing = [name for name, value in inputs.items() if value is None]
    if missing:
        rejected.append(
            _blocked(
                "missing-inputs",
                "Some runtime reports were missing",
                f"Missing inputs: {', '.join(sorted(missing))}.",
                "needs more evidence",
            )
        )

    if len(candidates) == 1 and candidates[0]["confidence"] < 0.5:
        rejected.append(
            _blocked(
                "low-evidence",
                "No stable memory candidate yet",
                "The available aggregate reports did not produce a high-confidence project-level lesson.",
                "needs more evidence",
            )
        )

    approval_packet = inputs.get("router_prompt_approval")
    if approval_packet:
        for item in _dict_list(approval_packet.get("blocked_items")):
            rejected.append(
                _blocked(
                    _safe_text(item.get("id"), default="blocked-approval-item"),
                    _safe_text(item.get("title"), default="Blocked approval item"),
                    _safe_text(item.get("blocked_reason"), default="Blocked by approval workflow."),
                    "would mutate behavior without approval",
                )
            )

    for name, report in inputs.items():
        if not report:
            continue
        if _contains_forbidden_raw_keys(report):
            rejected.append(
                _blocked(
                    f"{name}-raw-content",
                    f"{name} contains raw-looking fields",
                    "Input contains raw-looking fields and must not be converted into memory candidates automatically.",
                    "contains raw content",
                )
            )

    return rejected


def _candidate(
    *,
    index: int,
    category: str,
    title: str,
    proposed_memory_text: str,
    rationale: str,
    source_reports: list[str],
    confidence: float,
    risk: str,
) -> dict[str, Any]:
    return {
        "id": f"memory-candidate-{index:03d}",
        "category": category if category in CATEGORIES else "workflow",
        "title": _sanitize(title, limit=90),
        "proposed_memory_text": _sanitize(proposed_memory_text, limit=180),
        "rationale": _sanitize(rationale, limit=220),
        "source_reports": source_reports,
        "confidence": max(0.0, min(1.0, round(confidence, 2))),
        "risk": risk if risk in {"low", "medium", "high"} else "medium",
        "approval_required": True,
        "memory_write_supported": False,
    }


def _blocked(item_id: str, title: str, rationale: str, blocked_reason: str) -> dict[str, Any]:
    return {
        "id": _sanitize(item_id, limit=80),
        "title": _sanitize(title, limit=100),
        "rationale": _sanitize(rationale, limit=220),
        "blocked_reason": blocked_reason,
        "memory_write_supported": False,
        "human_review_required": True,
    }


def _validation_plan() -> list[str]:
    return [
        "make check-layout",
        "make check-python-syntax",
        "make test",
        "make test-router-prompt-approval",
        "make test-improvement-patch-plan",
        "make test-learning-loop-report",
    ]


def _safety_boundaries() -> list[str]:
    return [
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


def _reviewer_checklist() -> list[str]:
    return [
        "inspect each candidate",
        "reject vague or sensitive candidates",
        "approve only stable project-level lessons",
        "manually store approved memory later if desired",
        "confirm no runtime files are staged",
    ]


def _next_steps() -> list[str]:
    return [
        "Review candidates and rejected items manually.",
        "Approve only stable lessons that do not contain raw prompts, responses, credentials, or sensitive details.",
        "Use a separate human-approved workflow before storing any memory.",
        "Keep generated runtime reports out of git.",
    ]


def _renumber(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    for index, candidate in enumerate(candidates, start=1):
        candidate["id"] = f"memory-candidate-{index:03d}"
    return candidates


def _dedupe_candidates(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen = set()
    deduped = []
    for candidate in candidates:
        key = (candidate["category"], candidate["proposed_memory_text"])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(candidate)
    return deduped


def _available_sources(inputs: dict[str, dict[str, Any] | None]) -> list[str]:
    return [name for name, value in inputs.items() if value is not None]


def _map_category(value: object) -> str:
    if not isinstance(value, str):
        return "workflow"
    mapping = {
        "feedback": "workflow",
        "gateway": "tests",
        "prompt": "workflow",
        "prompts": "workflow",
        "router": "routing",
        "routing-alignment": "model",
        "model-routing": "model",
        "review": "workflow",
        "stability": "tests",
    }
    category = mapping.get(value, value)
    return category if category in CATEGORIES else "workflow"


def _risk(category: str) -> str:
    if category in {"routing", "model", "memory", "ops"}:
        return "medium"
    return "low"


def _dominant(counts: dict[str, int], total: int, *, ratio: float = 0.6) -> tuple[str, int] | None:
    if total <= 0 or not counts:
        return None
    key, count = sorted(counts.items(), key=lambda item: (-item[1], item[0]))[0]
    if count / total >= ratio:
        return key, count
    return None


def _confidence(record_count: int, base: float) -> float:
    if record_count <= 0:
        return 0.35
    return min(0.9, base + min(record_count, 20) / 100)


def _dict_of_ints(value: object) -> dict[str, int]:
    if not isinstance(value, dict):
        return {}
    return {str(key): count for key, count in value.items() if isinstance(count, int) and count >= 0}


def _dict_list(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def _top_tags(value: object) -> list[dict[str, Any]]:
    tags = []
    for item in _dict_list(value):
        tag = item.get("tag")
        count = item.get("count")
        if isinstance(tag, str) and isinstance(count, int):
            tags.append({"tag": tag, "count": count})
    return sorted(tags, key=lambda item: (-item["count"], item["tag"]))


def _safe_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int) and value >= 0:
        return value
    return 0


def _safe_text(value: object, *, default: str) -> str:
    if isinstance(value, str) and value.strip():
        return value.strip()
    return default


def _short_title(value: str) -> str:
    cleaned = _sanitize(value, limit=100)
    return cleaned[:1].lower() + cleaned[1:] if cleaned else "review aggregate lesson"


def _clean_fragment(value: str) -> str:
    return _sanitize(value, limit=48)


def _sanitize(value: str, *, limit: int) -> str:
    text = re.sub(r"(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*\S+", "[redacted]", value)
    text = re.sub(r"[\r\n\t]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    forbidden_markers = ["raw prompt", "raw response", "model response", "feedback record"]
    for marker in forbidden_markers:
        text = re.sub(re.escape(marker), "review content", text, flags=re.IGNORECASE)
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text


def _contains_forbidden_raw_keys(value: object) -> bool:
    forbidden = {"prompt", "response", "raw_prompt", "raw_response", "model_response", "feedback_records"}
    if isinstance(value, dict):
        for key, nested in value.items():
            if str(key).lower() in forbidden:
                return True
            if _contains_forbidden_raw_keys(nested):
                return True
    if isinstance(value, list):
        return any(_contains_forbidden_raw_keys(item) for item in value)
    return False


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
