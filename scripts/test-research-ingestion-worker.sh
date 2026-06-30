#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$(mktemp -d /tmp/moe-research-reports.XXXXXX)"
SOURCE_ROOT="$(mktemp -d /tmp/moe-research-source.XXXXXX)"

cleanup() {
  rm -rf "$REPORTS_DIR" "$SOURCE_ROOT"
}
trap cleanup EXIT

mkdir -p "$SOURCE_ROOT/docs" "$SOURCE_ROOT/configs"
cp "$ROOT/docs/architecture.md" "$SOURCE_ROOT/docs/architecture.md"
cp "$ROOT/docs/milestones.md" "$SOURCE_ROOT/docs/milestones.md"
cp "$ROOT/configs/research-sources.example.yaml" "$SOURCE_ROOT/configs/research-sources.example.yaml"

export PYTHONDONTWRITEBYTECODE=1
export RESEARCH_REPORTS_DIR="$REPORTS_DIR"
export RESEARCH_RUNTIME_ROOT="/tmp/moe-research-runtime"
export RESEARCH_SOURCE_ROOT="$SOURCE_ROOT"
export RESEARCH_SOURCES_CONFIG="$SOURCE_ROOT/configs/research-sources.example.yaml"
export RESEARCH_GATEWAY_URL="http://127.0.0.1:9"
export RESEARCH_MEMORY_API_URL="http://127.0.0.1:9"

python3 - "$ROOT" "$REPORTS_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
reports_dir = pathlib.Path(sys.argv[2]).resolve()
sys.path.insert(0, str(root / "apps/research-ingestion-worker"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Research Ingestion Worker tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/research-ingestion\n"
        "  source ~/MoE/runtime/venvs/research-ingestion/bin/activate\n"
        "  pip install -r apps/research-ingestion-worker/requirements.txt\n"
        "  make test-research-ingestion\n\n"
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
if health_body.get("status") != "ok" or health_body.get("service") != "research-ingestion-worker":
    fail(f"/health returned unexpected response: {health_body}")
print("PASS: Research Ingestion Worker /health")

latest_empty = client.get("/research/latest")
if latest_empty.status_code != 200 or latest_empty.json().get("status") != "empty":
    fail(f"/research/latest empty response unexpected: {latest_empty.text}")
print("PASS: Research Ingestion Worker /research/latest empty")

run = client.post(
    "/research/run",
    json={
        "mode": "dry_run",
        "source_set": "default",
        "store_findings": False,
    },
)
if run.status_code != 200:
    fail(f"/research/run returned HTTP {run.status_code}: {run.text}")
run_body = run.json()
summary = run_body.get("summary", {})
if run_body.get("status") != "ok" or run_body.get("mode") != "dry_run":
    fail(f"/research/run returned unexpected response: {run_body}")
if summary.get("sources_processed") != 2:
    fail(f"expected 2 processed sources, got: {summary}")
print("PASS: Research Ingestion Worker /research/run dry_run")

report_path = pathlib.Path(run_body["report_path"]).resolve()
if not report_path.is_file():
    fail(f"report file was not created: {report_path}")
if not report_path.is_relative_to(reports_dir):
    fail(f"report escaped allowed reports dir: {report_path}")

report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("remote_fetch_enabled") is not False:
    fail(f"remote_fetch_enabled must be false: {report.get('remote_fetch_enabled')}")
if report.get("safety") != {
    "remote_fetch_performed": False,
    "source_modified": False,
    "shell_executed": False,
}:
    fail(f"report safety block unexpected: {report.get('safety')}")
print("PASS: Research Ingestion Worker report safety")

latest = client.get("/research/latest")
if latest.status_code != 200 or latest.json().get("status") != "ok":
    fail(f"/research/latest returned unexpected response: {latest.text}")
print("PASS: Research Ingestion Worker /research/latest ok")

rejected = client.post("/research/run", json={"mode": "fetch"})
if rejected.status_code != 200 or rejected.json().get("status") != "rejected":
    fail(f"/research/run unsupported mode was not rejected: {rejected.text}")
print("PASS: Research Ingestion Worker rejects non-dry_run mode")

print("Research Ingestion Worker tests passed")
PY
