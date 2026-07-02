import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "router-prompt-update-approval"
APPROVAL_STATUS = "pending_human_review"
ALLOWED_CATEGORIES = {"router", "prompt", "docs", "tests", "model-routing"}
BLOCKED_CATEGORIES = {"memory", "ops"}


def read_patch_plan(patch_plan_path: str | Path) -> dict[str, Any]:
    path = Path(patch_plan_path).expanduser()
    return json.loads(path.read_text(encoding="utf-8"))


def build_router_prompt_approval_packet(
    patch_plan: dict[str, Any],
    *,
    source_patch_plan_path: str,
) -> dict[str, Any]:
    patch_groups = _safe_patch_groups(patch_plan.get("patch_groups"))
    approval_items = []
    blocked_items = []

    for group in patch_groups:
        category = _safe_category(group.get("category"))
        if category in ALLOWED_CATEGORIES and group.get("risk") != "high":
            approval_items.append(_approval_item(group, category))
        else:
            blocked_items.append(_blocked_item(group, category))

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_patch_plan_path": source_patch_plan_path,
        "approval_status": APPROVAL_STATUS,
        "apply_supported": False,
        "human_review_required": True,
        "approval_items": approval_items,
        "blocked_items": blocked_items,
        "validation_plan": _validation_plan(approval_items),
        "safety_boundaries": _safety_boundaries(),
        "reviewer_checklist": _reviewer_checklist(),
        "next_steps": _next_steps(),
    }


def write_router_prompt_approval_packet(
    approval_packet_path: str | Path,
    packet: dict[str, Any],
) -> Path:
    path = Path(approval_packet_path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(packet, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _approval_item(group: dict[str, Any], category: str) -> dict[str, Any]:
    return {
        "id": _safe_text(group.get("id"), default="patch-group"),
        "category": category,
        "title": _safe_text(group.get("title"), default="Review approved update candidate"),
        "rationale": _safe_text(group.get("rationale"), default="Human review is required."),
        "target_files": _target_files(group.get("target_files")),
        "proposed_update_summary": _update_summary(group, category),
        "risk": _safe_risk(group.get("risk")),
        "approval_required": True,
        "apply_supported": False,
        "suggested_validation": _suggested_validation(group, category),
    }


def _blocked_item(group: dict[str, Any], category: str) -> dict[str, Any]:
    risk = _safe_risk(group.get("risk"))
    reason = "category is outside router/prompt approval workflow"
    if category in BLOCKED_CATEGORIES:
        reason = f"{category} changes require a separate approval workflow"
    if risk == "high":
        reason = "high-risk item requires separate review"
    return {
        "id": _safe_text(group.get("id"), default="patch-group"),
        "category": category,
        "title": _safe_text(group.get("title"), default="Blocked update candidate"),
        "rationale": _safe_text(group.get("rationale"), default="Human review is required."),
        "target_files": _target_files(group.get("target_files")),
        "risk": risk,
        "blocked_reason": reason,
        "apply_supported": False,
        "human_review_required": True,
    }


def _update_summary(group: dict[str, Any], category: str) -> str:
    strategy = _safe_text(
        group.get("proposed_patch_strategy"),
        default="Review the proposed change manually before preparing any patch.",
    )
    return (
        f"A human-approved {category} update could use this reviewed strategy: {strategy} "
        "No files are modified by this approval packet."
    )


def _validation_plan(approval_items: list[dict[str, Any]]) -> list[str]:
    commands = [
        "make check-layout",
        "make check-python-syntax",
        "make test",
        "make test-gateway-chat-router",
        "make test-openai-compatible-gateway",
        "make test-improvement-patch-plan",
    ]
    categories = {item.get("category") for item in approval_items}
    if categories & {"docs", "tests"}:
        commands.append("make test-gateway-feedback")
    if "model-routing" in categories:
        commands.append("make model-registry-check")
    return commands


def _suggested_validation(group: dict[str, Any], category: str) -> list[str]:
    commands = []
    expected = group.get("expected_validation")
    if isinstance(expected, list):
        commands.extend(item for item in expected if isinstance(item, str))
    if category in {"router", "model-routing"}:
        commands.append("make test-gateway-chat-router")
    if category in {"prompt", "docs", "tests"}:
        commands.append("make test-gateway-feedback")
    commands.extend(["make check-layout", "make check-python-syntax", "make test"])
    return _dedupe(commands)


def _safety_boundaries() -> list[str]:
    return [
        "no automatic file edits",
        "no memory writes",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no prompt/router mutation without explicit human approval",
        "no training or fine-tuning",
        "no generated runtime report committed to repo",
    ]


def _reviewer_checklist() -> list[str]:
    return [
        "inspect approval_items",
        "verify target_files are source files only",
        "reject high-risk items",
        "run validation commands after manual edits",
        "review git diff before commit",
        "confirm no runtime files are staged",
    ]


def _next_steps() -> list[str]:
    return [
        "Review approval items and blocked items with a human.",
        "Approve individual router, prompt, docs, tests, or model-routing items explicitly.",
        "Create a separate implementation task for approved updates.",
        "Run validation commands and review git diff before commit.",
    ]


def _safe_patch_groups(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def _safe_category(value: object) -> str:
    if isinstance(value, str) and value:
        return value
    return "unknown"


def _target_files(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, str) and item.strip()]


def _safe_risk(value: object) -> str:
    if isinstance(value, str) and value in {"low", "medium", "high"}:
        return value
    return "medium"


def _safe_text(value: object, *, default: str) -> str:
    if isinstance(value, str) and value.strip():
        return value.strip()
    return default


def _dedupe(commands: list[str]) -> list[str]:
    deduped = []
    for command in commands:
        if command not in deduped:
            deduped.append(command)
    return deduped


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
