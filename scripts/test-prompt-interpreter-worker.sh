#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PYTHONDONTWRITEBYTECODE=1

python3 - "$ROOT" <<'PY'
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
sys.path.insert(0, str(root / "apps/prompt-interpreter-worker"))

try:
    from fastapi.testclient import TestClient
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi is required for local Prompt Interpreter Worker tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/prompt-interpreter\n"
        "  source ~/MoE/runtime/venvs/prompt-interpreter/bin/activate\n"
        "  pip install -r apps/prompt-interpreter-worker/requirements.txt\n"
        "  make test-prompt-interpreter-worker\n\n"
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
if health.json().get("model_enabled") is not False or health.json().get("generation_enabled") is not False:
    fail(f"/health safety flags unexpected: {health.text}")
print("PASS: Prompt Interpreter /health")

system_status = client.get("/system/status")
system_body = system_status.json()
if (
    system_status.status_code != 200
    or system_body.get("status") != "ok"
    or system_body.get("service") != "pc2-system-status"
    or system_body.get("read_only") is not True
    or not isinstance(system_body.get("memory"), dict)
    or not isinstance(system_body.get("cpu"), dict)
    or not isinstance(system_body.get("disk"), dict)
    or not isinstance(system_body.get("uptime"), dict)
):
    fail(f"/system/status returned unexpected response: {system_status.text}")
print("PASS: Prompt Interpreter /system/status")

image = client.post("/interpret", json={"prompt": "gerçekçi ahşap pergola görseli üret"})
if image.status_code != 200 or image.json().get("classification", {}).get("intent") != "image":
    fail(f"image prompt classification failed: {image.text}")
print("PASS: Prompt Interpreter image classification")

video = client.post("/interpret", json={"prompt": "short cinematic video shot of a wooden pergola"})
if video.status_code != 200 or video.json().get("classification", {}).get("intent") != "video":
    fail(f"video prompt classification failed: {video.text}")
print("PASS: Prompt Interpreter video classification")

suite = client.post("/interpret", json={"prompt": "3d model rig and animation plan for a simple robot"})
if suite.status_code != 200 or suite.json().get("classification", {}).get("intent") != "3d_suite":
    fail(f"3d suite prompt classification failed: {suite.text}")
print("PASS: Prompt Interpreter 3d_suite classification")

explicit = client.post(
    "/interpret",
    json={"prompt": "kamera hareketi olan sahne", "target_mode": "image"},
)
if explicit.status_code != 200 or explicit.json().get("classification", {}).get("intent") != "image":
    fail(f"explicit target mode failed: {explicit.text}")
print("PASS: Prompt Interpreter explicit target_mode=image")

empty = client.post("/interpret", json={"prompt": ""})
if empty.status_code != 422:
    fail(f"empty prompt should return 422, got {empty.status_code}: {empty.text}")
print("PASS: Prompt Interpreter rejects empty prompt")

non_dry = client.post("/interpret", json={"prompt": "image", "mode": "generate"})
if non_dry.status_code != 200 or non_dry.json().get("status") != "rejected":
    fail(f"non-dry mode should be rejected: {non_dry.text}")
print("PASS: Prompt Interpreter rejects non-dry mode")

batch = client.post(
    "/interpret/batch",
    json={
        "items": [
            {"prompt": "poster image"},
            {"prompt": "video clip"},
            {"prompt": "glb mesh model"},
        ]
    },
)
if batch.status_code != 200 or batch.json().get("count") != 3:
    fail(f"batch endpoint failed: {batch.text}")
print("PASS: Prompt Interpreter batch endpoint")

too_many = client.post(
    "/interpret/batch",
    json={"items": [{"prompt": f"image {index}"} for index in range(21)]},
)
if too_many.status_code != 422:
    fail(f"batch limit should return 422, got {too_many.status_code}: {too_many.text}")
print("PASS: Prompt Interpreter rejects batch over 20")

print("Prompt Interpreter Worker tests passed")
PY
