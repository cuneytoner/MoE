import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "reviewed-improvement-patch-planner"
PATCH_PLAN_STATUS = "review_required"
ALLOWED_CATEGORIES = {"router", "prompt", "docs", "tests", "memory", "model-routing", "ops"}


def read_improvement_plan(plan_path: str | Path) -> dict[str, Any]:
    path = Path(plan_path).expanduser()
    return json.loads(path.read_text(encoding="utf-8"))


def build_improvement_patch_plan(
    plan: dict[str, Any],
    *,
    source_plan_path: str,
) -> dict[str, Any]:
    patch_groups = _patch_groups(_safe_changes(plan.get("proposed_changes")))
    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_plan_path": source_plan_path,
        "source_plan_status": _safe_text(plan.get("plan_status"), default="unknown"),
        "apply_supported": False,
        "human_review_required": True,
        "patch_plan_status": PATCH_PLAN_STATUS,
        "patch_groups": patch_groups,
        "validation_plan": _validation_plan(patch_groups),
        "safety_boundaries": _safety_boundaries(),
        "review_checklist": _review_checklist(),
        "next_steps": _next_steps(),
    }


def write_improvement_patch_plan(patch_plan_path: str | Path, patch_plan: dict[str, Any]) -> Path:
    path = Path(patch_plan_path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(patch_plan, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _patch_groups(changes: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if not changes:
        return [
            _patch_group(
                index=1,
                category="docs",
                title="Review improvement plan manually",
                rationale="The improvement plan did not include proposed changes.",
                target_files=["docs/improvement-plan.md"],
                risk="low",
            )
        ]

    groups = []
    for index, change in enumerate(changes, start=1):
        category = _category(change.get("category"))
        groups.append(
            _patch_group(
                index=index,
                category=category,
                title=_safe_text(change.get("title"), default="Review proposed improvement"),
                rationale=_safe_text(
                    change.get("rationale"),
                    default="Human review is required before any patch is prepared.",
                ),
                target_files=_target_files(change.get("target_files"), category),
                risk=_risk(change.get("risk"), category),
            )
        )
    return groups


def _patch_group(
    *,
    index: int,
    category: str,
    title: str,
    rationale: str,
    target_files: list[str],
    risk: str,
) -> dict[str, Any]:
    return {
        "id": f"patch-group-{index:03d}",
        "category": category,
        "title": title,
        "rationale": rationale,
        "target_files": target_files,
        "proposed_patch_strategy": _strategy(category, target_files),
        "expected_validation": _expected_validation(category),
        "risk": risk,
        "apply_supported": False,
        "human_approval_required": True,
    }


def _strategy(category: str, target_files: list[str]) -> str:
    joined_targets = ", ".join(target_files)
    strategies = {
        "router": "Draft a small reviewed patch plan for router keyword or example changes; do not edit routing config until approved.",
        "prompt": "Draft prompt-template wording changes as reviewed text proposals; do not update prompt files automatically.",
        "docs": "Draft documentation-only edits for the listed files and review the rendered diff before committing.",
        "tests": "Draft focused test additions or assertions for the repeated feedback theme before changing behavior.",
        "memory": "Draft candidate memory entries for human review only; do not call Memory API or write memories.",
        "model-routing": "Draft routing-alignment review notes and tests; do not switch models or modify mappings automatically.",
        "ops": "Draft operational documentation changes and validation steps; do not control services or Docker.",
    }
    return f"{strategies.get(category, strategies['docs'])} Target files for review: {joined_targets}."


def _expected_validation(category: str) -> list[str]:
    commands = ["make check-layout", "make check-python-syntax", "make test"]
    if category in {"router", "model-routing"}:
        commands.append("make test-gateway-chat-router")
    if category in {"prompt", "docs", "tests", "memory", "ops"}:
        commands.append("make test-gateway-feedback")
    if category == "memory":
        commands.append("make test-gateway-memory-injection")
    if category == "tests":
        commands.append("make test-improvement-plan")
    return commands


def _validation_plan(patch_groups: list[dict[str, Any]]) -> list[str]:
    commands = ["make check-layout", "make check-python-syntax", "make test"]
    for group in patch_groups:
        for command in group.get("expected_validation", []):
            if command not in commands:
                commands.append(command)
    return commands


def _safety_boundaries() -> list[str]:
    return [
        "no automatic file edits",
        "no memory writes",
        "no model switching",
        "no Docker control",
        "no shell execution from apps",
        "no prompt/router mutation without approval",
        "no training or fine-tuning",
        "no generated runtime report committed to repo",
    ]


def _review_checklist() -> list[str]:
    return [
        "confirm target files are correct",
        "inspect risk level",
        "run validation commands",
        "review git diff before commit",
        "confirm no runtime files are staged",
    ]


def _next_steps() -> list[str]:
    return [
        "Review each patch group with a human before implementation.",
        "Create a separate approved implementation task for selected patch groups.",
        "Keep generated runtime reports out of git.",
        "Run the validation plan after any approved patch implementation.",
    ]


def _safe_changes(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def _category(value: object) -> str:
    if isinstance(value, str) and value in ALLOWED_CATEGORIES:
        return value
    return "docs"


def _target_files(value: object, category: str) -> list[str]:
    if isinstance(value, list):
        targets = [item for item in value if isinstance(item, str) and item.strip()]
        if targets:
            return targets
    defaults = {
        "router": ["configs/model-routing.yaml", "apps/gateway-api/app/services/chat_router.py"],
        "prompt": ["docs/codex-prompts.md", "docs/gateway-chat.md"],
        "docs": ["docs/improvement-plan.md", "docs/improvement-patch-planner.md"],
        "tests": ["scripts/test-improvement-plan.sh", "scripts/test-improvement-patch-plan.sh"],
        "memory": ["docs/memory-injection.md", "docs/memory-api.md"],
        "model-routing": ["configs/model-routing.yaml", "docs/models.md"],
        "ops": ["docs/runtime-command-pack.md", "docs/deployment.md"],
    }
    return defaults.get(category, defaults["docs"])


def _risk(value: object, category: str) -> str:
    if isinstance(value, str) and value in {"low", "medium", "high"}:
        return value
    if category in {"router", "prompt", "model-routing", "memory"}:
        return "medium"
    if category == "ops":
        return "high"
    return "low"


def _safe_text(value: object, *, default: str) -> str:
    if isinstance(value, str) and value.strip():
        return value.strip()
    return default


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
