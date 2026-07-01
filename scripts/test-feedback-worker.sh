#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$(mktemp -d /tmp/moe-feedback-data.XXXXXX)"
REPORTS_DIR="$(mktemp -d /tmp/moe-feedback-reports.XXXXXX)"
IMPROVEMENT_REPORTS_DIR="$(mktemp -d /tmp/moe-improvement-reports.XXXXXX)"
BRIDGE_REPORTS_DIR="$(mktemp -d /tmp/moe-feedback-bridge-reports.XXXXXX)"

cleanup() {
  rm -rf "$DATA_DIR" "$REPORTS_DIR" "$IMPROVEMENT_REPORTS_DIR" "$BRIDGE_REPORTS_DIR"
}
trap cleanup EXIT

export PYTHONDONTWRITEBYTECODE=1
export FEEDBACK_RUNTIME_ROOT="/tmp/moe-feedback-runtime"
export FEEDBACK_DATA_DIR="$DATA_DIR"
export FEEDBACK_EVENTS_FILE="$DATA_DIR/events.jsonl"
export FEEDBACK_JSONL_PATH="$DATA_DIR/gateway-feedback.jsonl"
export FEEDBACK_SUMMARY_PATH="$BRIDGE_REPORTS_DIR/feedback-summary.json"
export FEEDBACK_REPORTS_DIR="$REPORTS_DIR"
export IMPROVEMENT_REPORTS_DIR="$IMPROVEMENT_REPORTS_DIR"
export FEEDBACK_MEMORY_API_URL="http://127.0.0.1:9"

python3 - "$ROOT" "$DATA_DIR" "$REPORTS_DIR" "$IMPROVEMENT_REPORTS_DIR" "$BRIDGE_REPORTS_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
data_dir = pathlib.Path(sys.argv[2]).resolve()
reports_dir = pathlib.Path(sys.argv[3]).resolve()
improvement_reports_dir = pathlib.Path(sys.argv[4]).resolve()
bridge_reports_dir = pathlib.Path(sys.argv[5]).resolve()
sys.path.insert(0, str(root / "apps/feedback-worker"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Feedback Worker tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/feedback-worker\n"
        "  source ~/MoE/runtime/venvs/feedback-worker/bin/activate\n"
        "  pip install -r apps/feedback-worker/requirements.txt\n"
        "  make test-feedback-worker\n\n"
        "Do not create a virtualenv inside the codebase."
    ) from exc

from app.config import get_settings
from app.main import app

get_settings.cache_clear()
client = TestClient(app)


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


health = client.get("/health")
if health.status_code != 200:
    fail(f"/health returned HTTP {health.status_code}: {health.text}")
health_body = health.json()
if health_body.get("status") != "ok" or health_body.get("service") != "feedback-worker":
    fail(f"/health returned unexpected response: {health_body}")
print("PASS: Feedback Worker /health")

event = client.post(
    "/feedback/event",
    json={
        "task_type": "coding",
        "goal": "test feedback event",
        "route_intent": "code",
        "model_target": "qwen-coder-14b-fast",
        "actual_model": "qwen-coder-14b-fast",
        "tools": ["code_context", "code_patch_plan"],
        "selected_files": ["docs/gateway-api.md"],
        "tests_run": ["make test"],
        "outcome": "success",
        "failure_reason": "",
        "notes": "local test event",
    },
)
if event.status_code != 200 or event.json().get("status") != "ok":
    fail(f"/feedback/event returned unexpected response: {event.text}")
event_body = event.json()["event"]
if not event_body.get("task_id") or not event_body.get("created_at"):
    fail(f"stored event missing generated metadata: {event_body}")
events_file = data_dir / "events.jsonl"
if not events_file.is_file():
    fail(f"events file was not created: {events_file}")
print("PASS: Feedback Worker /feedback/event")

events = client.get("/feedback/events")
if events.status_code != 200 or events.json().get("status") != "ok":
    fail(f"/feedback/events returned unexpected response: {events.text}")
if len(events.json().get("events", [])) != 1:
    fail(f"expected 1 event, got: {events.text}")
print("PASS: Feedback Worker /feedback/events")

gateway_feedback_path = data_dir / "gateway-feedback.jsonl"
gateway_feedback_path.write_text(
    "\n".join(
        [
            json.dumps(
                {
                    "created_at": "2026-01-01T00:00:00Z",
                    "service": "gateway-feedback",
                    "source": "manual",
                    "rating": "useful",
                    "tags": ["m28", "feedback"],
                    "router_intent": "architecture",
                    "model": "gateway-auto",
                    "reason": "not included in summary",
                },
                sort_keys=True,
            ),
            "{malformed",
            "",
        ]
    )
    + "\n",
    encoding="utf-8",
)

bridge_status = client.get("/feedback/status")
if bridge_status.status_code != 200 or bridge_status.json().get("status") != "ok":
    fail(f"/feedback/status returned unexpected response: {bridge_status.text}")
bridge_status_body = bridge_status.json()
if bridge_status_body.get("service") != "feedback-worker":
    fail(f"/feedback/status returned bad service: {bridge_status_body}")
if bridge_status_body.get("record_count") != 1:
    fail(f"/feedback/status returned bad record count: {bridge_status_body}")
if bridge_status_body.get("ratings", {}).get("useful") != 1:
    fail(f"/feedback/status returned bad ratings: {bridge_status_body}")
print("PASS: Feedback Worker /feedback/status bridge")

bridge_summary = client.post("/feedback/summarize")
if bridge_summary.status_code != 200 or bridge_summary.json().get("status") != "ok":
    fail(f"/feedback/summarize returned unexpected response: {bridge_summary.text}")
bridge_summary_body = bridge_summary.json()
bridge_summary_path = pathlib.Path(bridge_summary_body["summary_path"]).resolve()
if not bridge_summary_path.is_file():
    fail(f"bridge summary file was not created: {bridge_summary_path}")
if not bridge_summary_path.is_relative_to(bridge_reports_dir):
    fail(f"bridge summary escaped allowed reports dir: {bridge_summary_path}")
bridge_summary_data = json.loads(bridge_summary_path.read_text(encoding="utf-8"))
if bridge_summary_data.get("malformed_count") != 1:
    fail(f"bridge summary malformed_count unexpected: {bridge_summary_data}")
if "reason" in json.dumps(bridge_summary_data):
    fail(f"bridge summary must not include reason text: {bridge_summary_data}")
print("PASS: Feedback Worker /feedback/summarize bridge")

report = client.post(
    "/feedback/report",
    json={"mode": "dry_run", "limit": 100, "store_lessons": False},
)
if report.status_code != 200 or report.json().get("status") != "ok":
    fail(f"/feedback/report returned unexpected response: {report.text}")
report_body = report.json()
report_path = pathlib.Path(report_body["report_path"]).resolve()
if not report_path.is_file():
    fail(f"report file was not created: {report_path}")
if not report_path.is_relative_to(reports_dir):
    fail(f"report escaped allowed reports dir: {report_path}")
report_data = json.loads(report_path.read_text(encoding="utf-8"))
if report_data.get("safety", {}).get("router_modified") is not False:
    fail(f"report safety block unexpected: {report_data.get('safety')}")
print("PASS: Feedback Worker /feedback/report dry_run")

latest = client.get("/feedback/latest-report")
if latest.status_code != 200 or latest.json().get("status") != "ok":
    fail(f"/feedback/latest-report returned unexpected response: {latest.text}")
print("PASS: Feedback Worker /feedback/latest-report")

rejected = client.post("/feedback/report", json={"mode": "apply"})
if rejected.status_code != 200 or rejected.json().get("status") != "rejected":
    fail(f"/feedback/report unsupported mode was not rejected: {rejected.text}")
print("PASS: Feedback Worker rejects non-dry_run report mode")

improvement = client.post(
    "/improvement/report",
    json={
        "mode": "dry_run",
        "limit": 100,
        "include_router_recommendations": True,
        "include_model_mapping_recommendations": True,
        "include_prompt_recommendations": True,
        "include_test_recommendations": True,
        "store_lessons": False,
    },
)
if improvement.status_code != 200 or improvement.json().get("status") != "ok":
    fail(f"/improvement/report returned unexpected response: {improvement.text}")
improvement_body = improvement.json()
if improvement_body.get("apply_supported") is not False:
    fail(f"/improvement/report must return apply_supported=false: {improvement_body}")
improvement_path = pathlib.Path(improvement_body["report_path"]).resolve()
if not improvement_path.is_file():
    fail(f"improvement report file was not created: {improvement_path}")
if not improvement_path.is_relative_to(improvement_reports_dir):
    fail(f"improvement report escaped allowed reports dir: {improvement_path}")
improvement_data = json.loads(improvement_path.read_text(encoding="utf-8"))
if improvement_data.get("safety", {}).get("apply_supported") is not False:
    fail(f"improvement report safety block unexpected: {improvement_data.get('safety')}")
print("PASS: Feedback Worker /improvement/report dry_run")

latest_improvement = client.get("/improvement/latest-report")
if latest_improvement.status_code != 200 or latest_improvement.json().get("status") != "ok":
    fail(f"/improvement/latest-report returned unexpected response: {latest_improvement.text}")
print("PASS: Feedback Worker /improvement/latest-report")

rejected_improvement = client.post("/improvement/report", json={"mode": "apply"})
if rejected_improvement.status_code != 200 or rejected_improvement.json().get("status") != "rejected":
    fail(f"/improvement/report unsupported mode was not rejected: {rejected_improvement.text}")
print("PASS: Feedback Worker rejects non-dry_run improvement mode")

print("Feedback Worker tests passed")
PY
