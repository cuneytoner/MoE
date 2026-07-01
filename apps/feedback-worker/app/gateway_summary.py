import json
from collections import Counter
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


RATINGS = ("accepted", "rejected", "useful", "not_useful", "neutral")


def feedback_status(feedback_path: str) -> dict[str, Any]:
    source_path = Path(feedback_path).expanduser()
    summary = summarize_feedback_file(source_path, include_malformed=False)
    return {
        "status": "ok",
        "service": "feedback-worker",
        "feedback_path": str(source_path),
        "exists": source_path.exists(),
        "record_count": summary["record_count"],
        "latest_created_at": summary["latest_created_at"],
        "ratings": summary["rating_counts"],
    }


def summarize_feedback_file(
    source_path: str | Path,
    *,
    include_malformed: bool = True,
) -> dict[str, Any]:
    path = Path(source_path).expanduser()
    rating_counts: Counter[str] = Counter()
    source_counts: Counter[str] = Counter()
    router_intent_counts: Counter[str] = Counter()
    model_counts: Counter[str] = Counter()
    tag_counts: Counter[str] = Counter()
    record_count = 0
    malformed_count = 0
    latest_created_at: str | None = None

    if path.exists():
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    malformed_count += 1
                    continue
                if not isinstance(record, dict):
                    malformed_count += 1
                    continue

                record_count += 1
                _count(rating_counts, record.get("rating"), default="neutral")
                _count(source_counts, record.get("source"))
                _count(router_intent_counts, record.get("router_intent"))
                _count(model_counts, record.get("model"))
                for tag in _safe_tags(record.get("tags")):
                    tag_counts[tag] += 1

                created_at = record.get("created_at")
                if isinstance(created_at, str) and (
                    latest_created_at is None or created_at > latest_created_at
                ):
                    latest_created_at = created_at

    summary = {
        "generated_at": _utc_now(),
        "source_path": str(path),
        "record_count": record_count,
        "malformed_count": malformed_count if include_malformed else 0,
        "rating_counts": _rating_counts(rating_counts),
        "source_counts": _sorted_counts(source_counts),
        "router_intent_counts": _sorted_counts(router_intent_counts),
        "model_counts": _sorted_counts(model_counts),
        "top_tags": [
            {"tag": tag, "count": count}
            for tag, count in sorted(tag_counts.items(), key=lambda item: (-item[1], item[0]))[:20]
        ],
        "latest_created_at": latest_created_at,
    }
    return summary


def write_summary(summary_path: str | Path, summary: dict[str, Any]) -> Path:
    path = Path(summary_path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _count(counter: Counter[str], value: object, *, default: str = "unknown") -> None:
    if isinstance(value, str) and value.strip():
        counter[value] += 1
    else:
        counter[default] += 1


def _rating_counts(counter: Counter[str]) -> dict[str, int]:
    return {rating: counter.get(rating, 0) for rating in RATINGS}


def _safe_tags(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    tags = []
    for item in value:
        if isinstance(item, str) and item.strip():
            tags.append(item)
    return tags


def _sorted_counts(counter: Counter[str]) -> dict[str, int]:
    return dict(sorted(counter.items(), key=lambda item: (-item[1], item[0])))


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
