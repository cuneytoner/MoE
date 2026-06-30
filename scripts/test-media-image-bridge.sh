#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA_ROOT="$(mktemp -d /tmp/moe-media-bridge-root.XXXXXX)"
REPORTS_DIR="$(mktemp -d /tmp/moe-media-bridge-reports.XXXXXX)"

cleanup() {
  rm -rf "$MEDIA_ROOT" "$REPORTS_DIR"
}
trap cleanup EXIT

export PYTHONDONTWRITEBYTECODE=1
export MEDIA_ROOT="$MEDIA_ROOT"
export MEDIA_JOBS_DIR="$MEDIA_ROOT/jobs"
export MEDIA_OUTPUTS_DIR="$MEDIA_ROOT/outputs"
export MEDIA_REPORTS_DIR="$REPORTS_DIR"
export MEDIA_REAL_GENERATION_ENABLED=false

python3 - "$ROOT" "$MEDIA_ROOT" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
media_root = pathlib.Path(sys.argv[2]).resolve()
sys.path.insert(0, str(root / "apps/media-api"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Media Image Bridge tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/media-api\n"
        "  source ~/MoE/runtime/venvs/media-api/bin/activate\n"
        "  pip install -r apps/media-api/requirements.txt\n"
        "  make test-media-image-bridge\n\n"
        "Do not create a virtualenv inside the codebase."
    ) from exc

from app.config import get_settings
from app.main import app

get_settings.cache_clear()
client = TestClient(app)


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


dry = client.post(
    "/media/jobs",
    json={
        "job_type": "image",
        "mode": "dry_run",
        "prompt": "bridge dry run",
        "workflow": "image_default",
        "metadata": {"width": 512, "height": 512, "steps": 4, "engine": "disabled"},
    },
)
if dry.status_code != 200 or dry.json().get("status") != "ok":
    fail(f"dry-run image job failed: {dry.text}")
job = dry.json()["job"]
if not pathlib.Path(job["job_path"]).resolve().is_relative_to(media_root / "jobs"):
    fail(f"job path escaped media jobs dir: {job['job_path']}")
print("PASS: Media image bridge dry-run job creation")

processed = client.post(f"/media/jobs/{job['job_id']}/process")
if processed.status_code != 200 or processed.json().get("status") != "ok":
    fail(f"dry-run process failed: {processed.text}")
print("PASS: Media image bridge dry-run process")

real = client.post(
    "/media/jobs",
    json={
        "job_type": "image",
        "mode": "real",
        "prompt": "real should be rejected",
        "workflow": "flux_schnell",
        "metadata": {"width": 512, "height": 512, "steps": 4, "engine": "comfyui"},
    },
)
if real.status_code != 200 or real.json().get("status") != "rejected":
    fail(f"real job should be rejected by default: {real.text}")
print("PASS: Media image bridge rejects real by default")

invalid = client.post("/media/jobs", json={"job_type": "audio", "mode": "dry_run", "prompt": "bad"})
if invalid.status_code != 422:
    fail(f"invalid job should return 422, got {invalid.status_code}: {invalid.text}")
print("PASS: Media image bridge rejects invalid job")

status = client.get(f"/media/jobs/{job['job_id']}")
if status.status_code != 200 or status.json().get("status") != "ok":
    fail(f"job status failed: {status.text}")
print("PASS: Media image bridge job status")

print("Media image bridge tests passed")
PY
