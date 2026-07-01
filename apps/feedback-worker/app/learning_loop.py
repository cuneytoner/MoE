import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


SERVICE_NAME = "learning-loop-report"


def build_learning_loop_report(
    summary: dict[str, Any],
    *,
    source_summary_path: str,
) -> dict[str, Any]:
    rating_counts = _dict_of_ints(summary.get("rating_counts"))
    source_counts = _dict_of_ints(summary.get("source_counts"))
    router_intent_counts = _dict_of_ints(summary.get("router_intent_counts"))
    model_counts = _dict_of_ints(summary.get("model_counts"))
    top_tags = _safe_top_tags(summary.get("top_tags"))
    source_record_count = _safe_int(summary.get("record_count"))

    observations = _observations(
        source_record_count=source_record_count,
        rating_counts=rating_counts,
        router_intent_counts=router_intent_counts,
        model_counts=model_counts,
        top_tags=top_tags,
    )
    recommendations = _recommendations(
        source_record_count=source_record_count,
        rating_counts=rating_counts,
        router_intent_counts=router_intent_counts,
        model_counts=model_counts,
        top_tags=top_tags,
    )

    return {
        "generated_at": _utc_now(),
        "service": SERVICE_NAME,
        "source_summary_path": source_summary_path,
        "source_record_count": source_record_count,
        "rating_counts": rating_counts,
        "source_counts": source_counts,
        "router_intent_counts": router_intent_counts,
        "model_counts": model_counts,
        "top_tags": top_tags,
        "observations": observations,
        "recommendations": recommendations,
        "apply_supported": False,
        "human_review_required": True,
    }


def read_summary(summary_path: str | Path) -> dict[str, Any]:
    path = Path(summary_path).expanduser()
    return json.loads(path.read_text(encoding="utf-8"))


def write_learning_loop_report(report_path: str | Path, report: dict[str, Any]) -> Path:
    path = Path(report_path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _observations(
    *,
    source_record_count: int,
    rating_counts: dict[str, int],
    router_intent_counts: dict[str, int],
    model_counts: dict[str, int],
    top_tags: list[dict[str, Any]],
) -> list[str]:
    positive = rating_counts.get("accepted", 0) + rating_counts.get("useful", 0)
    negative = rating_counts.get("rejected", 0) + rating_counts.get("not_useful", 0)
    observations = [
        f"Analyzed {source_record_count} aggregate feedback records.",
        f"Positive ratings total {positive}; rejected or not useful ratings total {negative}.",
    ]

    dominant_intent = _dominant(router_intent_counts, source_record_count)
    if dominant_intent:
        observations.append(
            f"Router intent '{dominant_intent[0]}' dominates the summary with {dominant_intent[1]} records."
        )

    dominant_model = _dominant(model_counts, source_record_count)
    if dominant_model:
        observations.append(
            f"Model '{dominant_model[0]}' dominates the summary with {dominant_model[1]} records."
        )

    if top_tags:
        observations.append(
            "Top feedback tags: "
            + ", ".join(f"{item['tag']}={item['count']}" for item in top_tags[:5])
            + "."
        )

    return observations


def _recommendations(
    *,
    source_record_count: int,
    rating_counts: dict[str, int],
    router_intent_counts: dict[str, int],
    model_counts: dict[str, int],
    top_tags: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    recommendations: list[dict[str, Any]] = []
    positive = rating_counts.get("accepted", 0) + rating_counts.get("useful", 0)
    negative = rating_counts.get("rejected", 0) + rating_counts.get("not_useful", 0)
    neutral = rating_counts.get("neutral", 0)

    if source_record_count == 0:
        recommendations.append(
            _recommendation(
                "feedback",
                "Collect more feedback before changing behavior",
                "The aggregate summary has no feedback records.",
                "Keep gathering reviewed Gateway feedback before modifying prompts, routing, memory, or models.",
            )
        )
        return recommendations

    if negative >= max(2, source_record_count // 3):
        recommendations.append(
            _recommendation(
                "prompts",
                "Review prompt guidance before implementation changes",
                "Rejected and not useful ratings are high enough to warrant human review.",
                "Inspect representative tasks manually and update docs or tests before considering prompt changes.",
            )
        )

    if positive > negative and positive >= max(2, source_record_count // 2):
        recommendations.append(
            _recommendation(
                "stability",
                "Preserve current useful behavior",
                "Useful and accepted ratings dominate the aggregate feedback.",
                "Prefer regression tests and documentation updates before changing routing or prompt behavior.",
            )
        )

    if neutral >= max(2, source_record_count // 2):
        recommendations.append(
            _recommendation(
                "feedback",
                "Clarify feedback collection labels",
                "Neutral ratings dominate the aggregate feedback.",
                "Review feedback source guidance so future ratings distinguish useful, accepted, rejected, and not useful outcomes.",
            )
        )

    dominant_intent = _dominant(router_intent_counts, source_record_count)
    if dominant_intent:
        recommendations.append(
            _recommendation(
                "router",
                f"Add review examples for router intent '{dominant_intent[0]}'",
                "One router intent dominates the feedback summary.",
                "Add human-reviewed docs or tests for this intent before changing router config.",
            )
        )

    dominant_model = _dominant(model_counts, source_record_count, ratio=0.75)
    if dominant_model:
        recommendations.append(
            _recommendation(
                "routing-alignment",
                f"Check routing alignment for model '{dominant_model[0]}'",
                "One model dominates the aggregate feedback summary.",
                "Compare intended routing with actual model usage during review; do not switch models automatically.",
            )
        )

    tag_names = {item["tag"] for item in top_tags}
    tag_recommendations = {
        "gateway": ("gateway", "Add Gateway feedback regression coverage"),
        "memory": ("memory", "Review memory-injection documentation and tests"),
        "router": ("router", "Review router examples and route metadata tests"),
        "feedback": ("feedback", "Improve feedback capture and summary documentation"),
        "docs": ("docs", "Update docs around repeated feedback themes"),
        "tests": ("tests", "Add or refine tests for repeated feedback themes"),
    }
    for tag, (category, title) in tag_recommendations.items():
        if tag in tag_names:
            recommendations.append(
                _recommendation(
                    category,
                    title,
                    f"The top tags include '{tag}'.",
                    "Create a human-reviewed follow-up task; keep this report advisory only.",
                )
            )

    if not recommendations:
        recommendations.append(
            _recommendation(
                "review",
                "Continue manual review before changes",
                "No deterministic aggregate trigger crossed the report thresholds.",
                "Keep collecting feedback and review future summaries before changing system behavior.",
            )
        )

    return recommendations


def _recommendation(
    category: str,
    title: str,
    reason: str,
    suggested_review: str,
) -> dict[str, Any]:
    return {
        "category": category,
        "title": title,
        "reason": reason,
        "suggested_review": suggested_review,
        "apply_supported": False,
        "human_review_required": True,
    }


def _dominant(
    counts: dict[str, int],
    total: int,
    *,
    ratio: float = 0.6,
) -> tuple[str, int] | None:
    if total <= 0 or not counts:
        return None
    key, count = sorted(counts.items(), key=lambda item: (-item[1], item[0]))[0]
    if count / total >= ratio:
        return key, count
    return None


def _safe_top_tags(value: object) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    tags: list[dict[str, Any]] = []
    for item in value:
        if not isinstance(item, dict):
            continue
        tag = item.get("tag")
        count = item.get("count")
        if isinstance(tag, str) and isinstance(count, int):
            tags.append({"tag": tag, "count": count})
    return tags


def _dict_of_ints(value: object) -> dict[str, int]:
    if not isinstance(value, dict):
        return {}
    result = {}
    for key, count in value.items():
        if isinstance(key, str):
            result[key] = _safe_int(count)
    return dict(sorted(result.items(), key=lambda item: (-item[1], item[0])))


def _safe_int(value: object) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    return 0


def _utc_now() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")
