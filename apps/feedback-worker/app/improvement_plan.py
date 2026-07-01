import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "human-approved-improvement-plan"
PLAN_STATUS = "review_required"
ALLOWED_CATEGORIES = {"router", "prompt", "docs", "tests", "memory", "model-routing", "ops"}


def read_learning_loop_report(report_path: str | Path) -> dict[str, Any]:
    path = Path(report_path).expanduser()
    return json.loads(path.read_text(encoding="utf-8"))


def build_improvement_plan(
    report: dict[str, Any],
    *,
    source_report_path: str,
) -> dict[str, Any]:
    recommendations = _safe_recommendations(report.get("recommendations"))
    proposed_changes = _proposed_changes(recommendations)
    validation_plan = _validation_plan(proposed_changes)

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_report_path": source_report_path,
        "source_record_count": _safe_int(report.get("source_record_count")),
        "plan_status": PLAN_STATUS,
        "apply_supported": False,
        "human_review_required": True,
        "proposed_changes": proposed_changes,
        "validation_plan": validation_plan,
        "safety_boundaries": _safety_boundaries(),
        "next_steps": _next_steps(),
    }


def write_improvement_plan(plan_path: str | Path, plan: dict[str, Any]) -> Path:
    path = Path(plan_path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(plan, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _proposed_changes(recommendations: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if not recommendations:
        return [
            _change(
                index=1,
                category="docs",
                title="Review learning loop report manually",
                rationale="No deterministic recommendation was available in the learning loop report.",
                target_files=["docs/learning-loop.md"],
                risk="low",
            )
        ]

    changes = []
    for index, recommendation in enumerate(recommendations, start=1):
        category = _map_category(recommendation.get("category"))
        title = _safe_text(recommendation.get("title"), default="Review aggregate feedback recommendation")
        reason = _safe_text(recommendation.get("reason"), default="Aggregate feedback suggests review.")
        suggested_review = _safe_text(
            recommendation.get("suggested_review"),
            default="Create a human-reviewed follow-up before changing source files.",
        )
        changes.append(
            _change(
                index=index,
                category=category,
                title=title,
                rationale=f"{reason} {suggested_review}",
                target_files=_target_files(category),
                risk=_risk(category),
            )
        )
    return changes


def _change(
    *,
    index: int,
    category: str,
    title: str,
    rationale: str,
    target_files: list[str],
    risk: str,
) -> dict[str, Any]:
    return {
        "id": f"change-{index:03d}",
        "category": category,
        "title": title,
        "rationale": rationale,
        "target_files": target_files,
        "risk": risk,
        "apply_supported": False,
        "human_approval_required": True,
    }


def _validation_plan(proposed_changes: list[dict[str, Any]]) -> list[str]:
    commands = ["make check-layout", "make check-python-syntax", "make test"]
    categories = {change.get("category") for change in proposed_changes}
    if categories & {"router", "model-routing"}:
        commands.append("make test-gateway-chat-router")
    if categories & {"prompt", "docs", "tests", "memory", "ops"}:
        commands.append("make test-gateway-feedback")
    if "memory" in categories:
        commands.append("make test-gateway-memory-injection")
    if "tests" in categories:
        commands.append("make test-learning-loop-report")
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
    ]


def _next_steps() -> list[str]:
    return [
        "Review proposed changes manually.",
        "Select individual changes for a future approved implementation milestone.",
        "Create a separate patch plan before editing source, docs, prompts, router config, or tests.",
        "Run the listed validation commands after any approved implementation.",
    ]


def _target_files(category: str) -> list[str]:
    targets = {
        "router": ["configs/model-routing.yaml", "apps/gateway-api/app/services/chat_router.py"],
        "prompt": ["docs/codex-prompts.md", "docs/gateway-chat.md"],
        "docs": ["docs/feedback.md", "docs/learning-loop.md", "docs/improvement-plan.md"],
        "tests": ["scripts/test-gateway-feedback.sh", "scripts/test-learning-loop-report.sh"],
        "memory": ["docs/memory-injection.md", "docs/memory-api.md"],
        "model-routing": ["configs/model-routing.yaml", "docs/models.md"],
        "ops": ["docs/runtime-command-pack.md", "docs/deployment.md"],
    }
    return targets.get(category, ["docs/learning-loop.md"])


def _risk(category: str) -> str:
    if category in {"router", "prompt", "model-routing", "memory"}:
        return "medium"
    if category == "ops":
        return "high"
    return "low"


def _map_category(value: object) -> str:
    if not isinstance(value, str):
        return "docs"
    mapping = {
        "feedback": "docs",
        "gateway": "tests",
        "prompts": "prompt",
        "review": "docs",
        "routing-alignment": "model-routing",
        "stability": "tests",
    }
    category = mapping.get(value, value)
    if category in ALLOWED_CATEGORIES:
        return category
    return "docs"


def _safe_recommendations(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def _safe_text(value: object, *, default: str) -> str:
    if isinstance(value, str) and value.strip():
        return value.strip()
    return default


def _safe_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    return 0


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
