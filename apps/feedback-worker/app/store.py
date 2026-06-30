import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from app.config import Settings


VALID_TASK_TYPES = {"coding", "ops", "research", "nightly", "media", "unknown"}
VALID_OUTCOMES = {"success", "failure", "partial", "unknown"}


def append_event(settings: Settings, event: dict[str, Any]) -> dict[str, Any]:
    events_file = _safe_events_file(settings)
    events_file.parent.mkdir(parents=True, exist_ok=True)
    stored = {
        **event,
        "task_id": event.get("task_id") or f"task-{uuid4().hex[:12]}",
        "created_at": datetime.now(UTC).isoformat(),
    }
    with events_file.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(stored, sort_keys=True) + "\n")
    return stored


def read_events(
    settings: Settings,
    *,
    limit: int = 20,
    outcome: str | None = None,
) -> list[dict[str, Any]]:
    events_file = _safe_events_file(settings)
    if not events_file.exists():
        return []

    events: list[dict[str, Any]] = []
    for line in events_file.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if outcome and event.get("outcome") != outcome:
            continue
        events.append(event)
    return events[-limit:]


def summarize_events(events: list[dict[str, Any]]) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "total": len(events),
        "success": 0,
        "failure": 0,
        "partial": 0,
        "unknown": 0,
        "by_task_type": {},
        "by_route_intent": {},
        "by_model_target": {},
        "common_failure_reasons": {},
    }
    for event in events:
        outcome = event.get("outcome", "unknown")
        if outcome in VALID_OUTCOMES:
            summary[outcome] += 1
        else:
            summary["unknown"] += 1
        _count(summary["by_task_type"], event.get("task_type") or "unknown")
        _count(summary["by_route_intent"], event.get("route_intent") or "unknown")
        _count(summary["by_model_target"], event.get("model_target") or "unknown")
        if event.get("failure_reason"):
            _count(summary["common_failure_reasons"], event["failure_reason"])
    return summary


def _safe_events_file(settings: Settings) -> Path:
    data_dir = Path(settings.data_dir).expanduser().resolve()
    events_file = Path(settings.events_file).expanduser().resolve()
    if not events_file.is_relative_to(data_dir):
        raise ValueError("events file must be inside FEEDBACK_DATA_DIR")
    return events_file


def _count(bucket: dict[str, int], key: str) -> None:
    bucket[key] = bucket.get(key, 0) + 1
