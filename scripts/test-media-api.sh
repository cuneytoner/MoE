#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA_ROOT="$(mktemp -d /tmp/moe-media-root.XXXXXX)"
REPORTS_DIR="$(mktemp -d /tmp/moe-media-reports.XXXXXX)"

cleanup() {
  rm -rf "$MEDIA_ROOT" "$REPORTS_DIR"
}
trap cleanup EXIT

export PYTHONDONTWRITEBYTECODE=1
export MEDIA_RUNTIME_ROOT="/tmp/moe-media-runtime"
export MEDIA_ROOT="$MEDIA_ROOT"
export MEDIA_JOBS_DIR="$MEDIA_ROOT/jobs"
export MEDIA_OUTPUTS_DIR="$MEDIA_ROOT/outputs"
export MEDIA_REPORTS_DIR="$REPORTS_DIR"

python3 - "$ROOT" "$MEDIA_ROOT" "$REPORTS_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
media_root = pathlib.Path(sys.argv[2]).resolve()
reports_dir = pathlib.Path(sys.argv[3]).resolve()
sys.path.insert(0, str(root / "apps/media-api"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Media API tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/media-api\n"
        "  source ~/MoE/runtime/venvs/media-api/bin/activate\n"
        "  pip install -r apps/media-api/requirements.txt\n"
        "  make test-media-api\n\n"
        "Do not create a virtualenv inside the codebase."
    ) from exc

from app.config import get_settings
from app.main import app

get_settings.cache_clear()
client = TestClient(app)


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


health = client.get("/health")
if health.status_code != 200 or health.json().get("status") != "ok":
    fail(f"/health returned unexpected response: {health.text}")
print("PASS: Media API /health")

created = client.post(
    "/media/jobs",
    json={
        "job_type": "image",
        "mode": "dry_run",
        "prompt": "test image dry run",
        "workflow": "default",
        "metadata": {"test": True},
    },
)
if created.status_code != 200 or created.json().get("status") != "ok":
    fail(f"/media/jobs returned unexpected response: {created.text}")
job = created.json()["job"]
job_path = pathlib.Path(job["job_path"]).resolve()
if not job_path.is_file() or not job_path.is_relative_to(media_root / "jobs"):
    fail(f"job was not stored under temp jobs dir: {job_path}")
print("PASS: Media API /media/jobs dry_run")

rejected = client.post(
    "/media/jobs",
    json={"job_type": "image", "mode": "generate", "prompt": "nope"},
)
if rejected.status_code != 200 or rejected.json().get("status") != "rejected":
    fail(f"non-dry_run job was not rejected: {rejected.text}")
print("PASS: Media API rejects non-dry_run")

invalid = client.post(
    "/media/jobs",
    json={"job_type": "audio", "mode": "dry_run", "prompt": "invalid"},
)
if invalid.status_code != 422:
    fail(f"invalid job_type should return validation error, got: {invalid.status_code} {invalid.text}")
print("PASS: Media API rejects invalid job_type")

fetched = client.get(f"/media/jobs/{job['job_id']}")
if fetched.status_code != 200 or fetched.json().get("status") != "ok":
    fail(f"/media/jobs/{{job_id}} returned unexpected response: {fetched.text}")
print("PASS: Media API /media/jobs/{job_id}")

processed = client.post(f"/media/jobs/{job['job_id']}/dry-run-process")
if processed.status_code != 200 or processed.json().get("status") != "ok":
    fail(f"dry-run process returned unexpected response: {processed.text}")
report_path = pathlib.Path(processed.json()["report_path"]).resolve()
if not report_path.is_file() or not report_path.is_relative_to(reports_dir):
    fail(f"report was not stored under temp reports dir: {report_path}")
report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("safety", {}).get("media_generated") is not False:
    fail(f"report safety block unexpected: {report.get('safety')}")
print("PASS: Media API dry-run process")

latest = client.get("/media/latest-report")
if latest.status_code != 200 or latest.json().get("status") != "ok":
    fail(f"/media/latest-report returned unexpected response: {latest.text}")
print("PASS: Media API /media/latest-report")

print("Media API tests passed")
PY
