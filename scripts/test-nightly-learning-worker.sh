#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$(mktemp -d /tmp/moe-nightly-reports.XXXXXX)"
SOURCE_ROOT="$(mktemp -d /tmp/moe-nightly-source.XXXXXX)"

cleanup() {
  rm -rf "$REPORTS_DIR" "$SOURCE_ROOT"
}
trap cleanup EXIT

export PYTHONDONTWRITEBYTECODE=1
export NIGHTLY_REPORTS_DIR="$REPORTS_DIR"
export NIGHTLY_RUNTIME_ROOT="/tmp/moe-nightly-runtime"
export NIGHTLY_SOURCE_ROOT="$SOURCE_ROOT"
export NIGHTLY_GATEWAY_URL="http://127.0.0.1:9"
export NIGHTLY_MEMORY_API_URL="http://127.0.0.1:9"

python3 - "$ROOT" "$REPORTS_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
reports_dir = pathlib.Path(sys.argv[2]).resolve()
sys.path.insert(0, str(root / "apps/nightly-learning-worker"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Nightly Learning Worker tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/nightly-learning\n"
        "  source ~/MoE/runtime/venvs/nightly-learning/bin/activate\n"
        "  pip install -r apps/nightly-learning-worker/requirements.txt\n"
        "  make test-nightly-learning\n\n"
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
if health_body.get("status") != "ok" or health_body.get("service") != "nightly-learning-worker":
    fail(f"/health returned unexpected response: {health_body}")
print("PASS: Nightly Learning Worker /health")

latest_empty = client.get("/nightly/latest")
if latest_empty.status_code != 200 or latest_empty.json().get("status") != "empty":
    fail(f"/nightly/latest empty response unexpected: {latest_empty.text}")
print("PASS: Nightly Learning Worker /nightly/latest empty")

run = client.post(
    "/nightly/run",
    json={
        "mode": "dry_run",
        "include_git_status": True,
        "include_gateway_summary": True,
        "include_memory_summary": True,
        "store_lessons": False,
    },
)
if run.status_code != 200:
    fail(f"/nightly/run returned HTTP {run.status_code}: {run.text}")
run_body = run.json()
if run_body.get("status") != "ok" or run_body.get("mode") != "dry_run":
    fail(f"/nightly/run returned unexpected response: {run_body}")
print("PASS: Nightly Learning Worker /nightly/run dry_run")

report_path = pathlib.Path(run_body["report_path"]).resolve()
if not report_path.is_file():
    fail(f"report file was not created: {report_path}")
if not report_path.is_relative_to(reports_dir):
    fail(f"report escaped allowed reports dir: {report_path}")

report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("safety") != {
    "source_modified": False,
    "patch_applied": False,
    "shell_executed": False,
}:
    fail(f"report safety block unexpected: {report.get('safety')}")
print("PASS: Nightly Learning Worker report safety")

latest = client.get("/nightly/latest")
if latest.status_code != 200 or latest.json().get("status") != "ok":
    fail(f"/nightly/latest returned unexpected response: {latest.text}")
print("PASS: Nightly Learning Worker /nightly/latest ok")

rejected = client.post("/nightly/run", json={"mode": "apply"})
if rejected.status_code != 200 or rejected.json().get("status") != "rejected":
    fail(f"/nightly/run unsupported mode was not rejected: {rejected.text}")
print("PASS: Nightly Learning Worker rejects non-dry_run mode")

print("Nightly Learning Worker tests passed")
PY
