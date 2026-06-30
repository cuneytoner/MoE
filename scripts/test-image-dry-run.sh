#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA_ROOT="$(mktemp -d /tmp/moe-image-media-root.XXXXXX)"
REPORTS_DIR="$(mktemp -d /tmp/moe-image-media-reports.XXXXXX)"

cleanup() {
  rm -rf "$MEDIA_ROOT" "$REPORTS_DIR"
}
trap cleanup EXIT

export PYTHONDONTWRITEBYTECODE=1
export MEDIA_RUNTIME_ROOT="/tmp/moe-image-media-runtime"
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
        "FAIL: fastapi is required for local image dry-run tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/media-api\n"
        "  source ~/MoE/runtime/venvs/media-api/bin/activate\n"
        "  pip install -r apps/media-api/requirements.txt\n"
        "  make test-image-dry-run\n\n"
        "Do not create a virtualenv inside the codebase."
    ) from exc

from app.config import get_settings
from app.main import app

get_settings.cache_clear()
client = TestClient(app)


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


created = client.post(
    "/media/jobs",
    json={
        "job_type": "image",
        "mode": "dry_run",
        "prompt": "dry run image",
        "negative_prompt": "",
        "workflow": "image_default",
        "metadata": {
            "width": 1024,
            "height": 1024,
            "steps": 4,
            "seed": 123,
            "engine": "disabled",
            "model_id": "flux-schnell-placeholder",
        },
    },
)
if created.status_code != 200 or created.json().get("status") != "ok":
    fail(f"image dry-run job was not accepted: {created.status_code} {created.text}")
job = created.json()["job"]
print("PASS: image dry-run job accepted")

invalid_width = client.post(
    "/media/jobs",
    json={
        "job_type": "image",
        "mode": "dry_run",
        "prompt": "invalid width",
        "metadata": {"width": 5000, "height": 1024},
    },
)
if invalid_width.status_code != 422:
    fail(f"invalid width should be rejected with 422, got: {invalid_width.status_code}")
print("PASS: invalid image width rejected")

non_dry = client.post(
    "/media/jobs",
    json={"job_type": "image", "mode": "generate", "prompt": "no generation"},
)
if non_dry.status_code != 200 or non_dry.json().get("status") != "rejected":
    fail(f"non-dry mode was not rejected: {non_dry.status_code} {non_dry.text}")
print("PASS: non-dry mode rejected")

processed = client.post(f"/media/jobs/{job['job_id']}/dry-run-process")
if processed.status_code != 200 or processed.json().get("status") != "ok":
    fail(f"image dry-run process failed: {processed.status_code} {processed.text}")
report_path = pathlib.Path(processed.json()["report_path"]).resolve()
if not report_path.is_file() or not report_path.is_relative_to(reports_dir):
    fail(f"report escaped temp reports dir: {report_path}")
report = json.loads(report_path.read_text(encoding="utf-8"))
image = report.get("image") or {}
if image.get("generation_performed") is not False or image.get("output_created") is not False:
    fail(f"image dry-run report safety fields unexpected: {image}")
print("PASS: image dry-run process report")

output_files = list((media_root / "outputs").glob("**/*")) if (media_root / "outputs").exists() else []
if output_files:
    fail(f"image dry-run created output files: {output_files}")
print("PASS: no image output file created")

print("Image dry-run tests passed")
PY
