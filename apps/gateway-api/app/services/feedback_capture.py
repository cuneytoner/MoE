import json
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from app.models.gateway import GatewayFeedbackRequest


SERVICE_NAME = "gateway-feedback"


def append_feedback(
    request: GatewayFeedbackRequest,
    path: str,
) -> dict[str, object]:
    feedback_path = Path(path)
    feedback_path.parent.mkdir(parents=True, exist_ok=True)

    record = _record_from_request(request)
    with feedback_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")))
        handle.write("\n")
    return record


def feedback_status(path: str) -> dict[str, object]:
    feedback_path = Path(path)
    if not feedback_path.exists():
        return {
            "status": "ok",
            "service": SERVICE_NAME,
            "path": str(feedback_path),
            "exists": False,
            "record_count": 0,
            "latest_created_at": None,
        }

    record_count = 0
    latest_created_at = None
    with feedback_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            record_count += 1
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            created_at = record.get("created_at")
            if isinstance(created_at, str):
                latest_created_at = created_at

    return {
        "status": "ok",
        "service": SERVICE_NAME,
        "path": str(feedback_path),
        "exists": True,
        "record_count": record_count,
        "latest_created_at": latest_created_at,
    }


def _record_from_request(request: GatewayFeedbackRequest) -> dict[str, object]:
    return {
        "id": uuid4().hex,
        "created_at": _utc_now(),
        "service": SERVICE_NAME,
        "read_only_control_plane": True,
        "source": request.source,
        "rating": request.rating,
        "reason": request.reason,
        "tags": request.tags,
        "request_id": request.request_id,
        "response_id": request.response_id,
        "router_intent": request.router_intent,
        "model": request.model,
    }


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
