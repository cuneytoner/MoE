import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "human-approved-memory-store-plan"
PLAN_STATUS = "pending_human_approval"
DEFAULT_MEMORY_API_URL = "http://127.0.0.1:8101"


def read_optional_json(path: str | Path) -> dict[str, Any] | None:
    expanded = Path(path).expanduser()
    if not expanded.exists():
        return None
    return json.loads(expanded.read_text(encoding="utf-8"))


def build_memory_store_plan(
    *,
    source_candidates_path: str,
    candidates_report: dict[str, Any] | None,
    approval_path: str,
    approval: dict[str, Any] | None,
    memory_api_url: str = DEFAULT_MEMORY_API_URL,
) -> dict[str, Any]:
    candidates = _candidate_list(candidates_report)
    approved_ids = _approved_ids(approval)
    approved_candidates = [
        _approved_candidate(candidate)
        for candidate in candidates
        if candidate.get("id") in approved_ids and _is_storable_candidate(candidate)
    ]
    blocked_candidates = [
        _blocked_candidate(candidate, approved_ids)
        for candidate in candidates
        if candidate.get("id") not in {item["id"] for item in approved_candidates}
    ]

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_candidates_path": source_candidates_path,
        "approval_path": approval_path,
        "approval_file_present": approval is not None,
        "plan_status": PLAN_STATUS,
        "memory_write_supported": False,
        "apply_supported": False,
        "human_review_required": True,
        "memory_api_url": memory_api_url,
        "approved_candidates": approved_candidates,
        "blocked_candidates": blocked_candidates,
        "manual_store_commands": _manual_store_commands(
            approved_candidates=approved_candidates,
            memory_api_url=memory_api_url,
        ),
        "validation_plan": _validation_plan(),
        "safety_boundaries": _safety_boundaries(),
        "reviewer_checklist": _reviewer_checklist(),
        "next_steps": _next_steps(),
    }


def write_memory_store_plan(path: str | Path, plan: dict[str, Any]) -> Path:
    expanded = Path(path).expanduser()
    expanded.parent.mkdir(parents=True, exist_ok=True)
    expanded.write_text(json.dumps(plan, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return expanded


def memory_add_payload(candidate: dict[str, Any]) -> dict[str, Any]:
    text = _sanitize(candidate.get("proposed_memory_text"), limit=500)
    return {
        "text": text,
        "source": "feedback-memory-candidate-review",
        "metadata": {
            "candidate_id": _sanitize(candidate.get("id"), limit=128),
            "category": _sanitize(candidate.get("category"), limit=64),
            "title": _sanitize(candidate.get("title"), limit=160),
            "risk": _sanitize(candidate.get("risk"), limit=32),
            "confidence": candidate.get("confidence"),
            "human_approved": True,
            "source": "memory-store-workflow",
        },
    }


def _candidate_list(report: dict[str, Any] | None) -> list[dict[str, Any]]:
    if not report:
        return []
    candidates = report.get("candidates")
    if not isinstance(candidates, list):
        return []
    return [candidate for candidate in candidates if isinstance(candidate, dict)]


def _approved_ids(approval: dict[str, Any] | None) -> set[str]:
    if not approval:
        return set()
    approved = approval.get("approved_candidate_ids")
    if not isinstance(approved, list):
        return set()
    return {item for item in approved if isinstance(item, str) and item.strip()}


def _is_storable_candidate(candidate: dict[str, Any]) -> bool:
    text = candidate.get("proposed_memory_text")
    return (
        isinstance(candidate.get("id"), str)
        and isinstance(text, str)
        and bool(text.strip())
        and candidate.get("memory_write_supported") is False
        and candidate.get("approval_required") is True
        and not _contains_forbidden_raw_markers(candidate)
    )


def _approved_candidate(candidate: dict[str, Any]) -> dict[str, Any]:
    result = {
        "id": _sanitize(candidate.get("id"), limit=128),
        "category": _sanitize(candidate.get("category"), limit=64),
        "title": _sanitize(candidate.get("title"), limit=160),
        "proposed_memory_text": _sanitize(candidate.get("proposed_memory_text"), limit=500),
        "rationale": _sanitize(candidate.get("rationale"), limit=260),
        "confidence": candidate.get("confidence"),
        "risk": _sanitize(candidate.get("risk"), limit=32),
        "approval_required": True,
        "memory_write_supported": False,
        "store_payload": None,
    }
    result["store_payload"] = memory_add_payload(result)
    return result


def _blocked_candidate(candidate: dict[str, Any], approved_ids: set[str]) -> dict[str, Any]:
    candidate_id = _sanitize(candidate.get("id"), limit=128)
    if candidate_id not in approved_ids:
        reason = "missing explicit human approval"
    elif _contains_forbidden_raw_markers(candidate):
        reason = "contains raw-looking content marker"
    else:
        reason = "candidate is not safe to store automatically"
    return {
        "id": candidate_id,
        "category": _sanitize(candidate.get("category"), limit=64),
        "title": _sanitize(candidate.get("title"), limit=160),
        "blocked_reason": reason,
        "memory_write_supported": False,
        "human_review_required": True,
    }


def _manual_store_commands(
    *,
    approved_candidates: list[dict[str, Any]],
    memory_api_url: str,
) -> list[str]:
    if not approved_candidates:
        return [
            "No Memory API calls are planned because no candidates have explicit human approval."
        ]

    commands = []
    for candidate in approved_candidates:
        payload = json.dumps(candidate["store_payload"], sort_keys=True)
        commands.append(
            "DRY-RUN ONLY; not executed by plan generation: "
            f"curl -sS {memory_api_url.rstrip('/')}/memory/add "
            "-H 'Content-Type: application/json' "
            f"-d '{payload}'"
        )
    return commands


def _validation_plan() -> list[str]:
    return [
        "make check-layout",
        "make check-python-syntax",
        "make test",
        "make test-feedback-memory-candidates",
        "make test-memory-store-workflow",
    ]


def _safety_boundaries() -> list[str]:
    return [
        "default mode is dry-run",
        "no Memory API writes without APPLY=1",
        "no memory writes during plan generation",
        "store only approved_candidates",
        "do not store blocked or pending candidates",
        "do not store raw prompts",
        "do not store raw model responses",
        "do not store raw feedback reason bodies",
        "do not store individual feedback records",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no training or fine-tuning",
        "no generated runtime report committed to repo",
    ]


def _reviewer_checklist() -> list[str]:
    return [
        "inspect each candidate before approval",
        "approve only stable project-level lessons",
        "reject vague, sensitive, or raw-content candidates",
        "create approved-memory-candidates.json manually with approved ids",
        "run make memory-store-plan-local after editing approvals",
        "run make memory-store-approved without APPLY=1 first",
        "use APPLY=1 only when ready to call Memory API",
        "confirm no runtime files are staged",
    ]


def _next_steps() -> list[str]:
    return [
        "Review blocked candidates and approve only safe memory candidates.",
        "Create /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json if storing is desired.",
        "Regenerate the plan and inspect dry-run commands.",
        "Run APPLY=1 make memory-store-approved only after explicit human approval.",
        "Generate a future memory store audit report.",
    ]


def _sanitize(value: object, *, limit: int) -> str:
    text = str(value or "")
    text = re.sub(r"(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*\S+", "[redacted]", text)
    text = re.sub(r"[\r\n\t]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    for marker in ("raw prompt", "raw response", "model response", "feedback record"):
        text = re.sub(re.escape(marker), "review content", text, flags=re.IGNORECASE)
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text


def _contains_forbidden_raw_markers(value: object) -> bool:
    forbidden = {
        "prompt",
        "response",
        "raw_prompt",
        "raw_response",
        "model_response",
        "feedback_records",
        "prompt_text",
        "response_text",
    }
    if isinstance(value, dict):
        for key, nested in value.items():
            if str(key).lower() in forbidden:
                return True
            if _contains_forbidden_raw_markers(nested):
                return True
    if isinstance(value, list):
        return any(_contains_forbidden_raw_markers(item) for item in value)
    return False


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
