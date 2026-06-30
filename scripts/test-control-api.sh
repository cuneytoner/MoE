#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PYTHONDONTWRITEBYTECODE=1
export CONTROL_MODE_CONFIG_PATH="$ROOT/configs/runtime-modes.example.yaml"

python3 - "$ROOT" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
sys.path.insert(0, str(root / "apps/control-api"))

try:
    from fastapi.testclient import TestClient
    import yaml  # noqa: F401
except ModuleNotFoundError as exc:
    raise SystemExit(
        "FAIL: fastapi and pyyaml are required for local Control API tests.\n\n"
        "Recommended source-only setup using a repo-external venv:\n"
        "  mkdir -p ~/MoE/runtime/venvs\n"
        "  python3 -m venv ~/MoE/runtime/venvs/control-api\n"
        "  source ~/MoE/runtime/venvs/control-api/bin/activate\n"
        "  pip install -r apps/control-api/requirements.txt\n"
        "  make control-api-test\n\n"
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
if health.json().get("arbitrary_shell_enabled") is not False:
    fail(f"/health arbitrary shell flag unexpected: {health.text}")
print("PASS: Control API /health")

status = client.get("/control/status")
if status.status_code != 200 or status.json().get("status") != "ok":
    fail(f"/control/status returned unexpected response: {status.text}")
for service in ("llama-server", "gateway-api", "comfyui", "prompt-interpreter-worker"):
    if service not in status.json().get("services", {}):
        fail(f"/control/status missing service: {service}")
print("PASS: Control API /control/status")

modes = client.get("/control/modes")
if modes.status_code != 200 or modes.json().get("status") != "ok":
    fail(f"/control/modes returned unexpected response: {modes.text}")
for mode in ("coding", "image", "video", "3d_suite", "media_off"):
    if mode not in modes.json().get("modes", {}):
        fail(f"/control/modes missing mode: {mode}")
print("PASS: Control API /control/modes")

for mode in ("coding", "image", "video", "3d_suite", "media_off"):
    plan = client.post("/control/mode/plan", json={"mode": mode})
    if plan.status_code != 200 or plan.json().get("status") != "ok":
        fail(f"/control/mode/plan {mode} returned unexpected response: {plan.text}")
    if plan.json().get("apply_supported") is not False:
        fail(f"/control/mode/plan {mode} should be dry-run only: {plan.text}")
    print(f"PASS: Control API /control/mode/plan {mode}")

invalid = client.post("/control/mode/plan", json={"mode": "bad_mode"})
if invalid.status_code not in (200, 422):
    fail(f"invalid mode should be rejected, got: {invalid.status_code} {invalid.text}")
print("PASS: Control API rejects invalid mode")

apply = client.post("/control/mode/apply", json={"mode": "image"})
if apply.status_code != 200 or apply.json().get("status") != "rejected":
    fail(f"/control/mode/apply should be rejected by default: {apply.text}")
print("PASS: Control API /control/mode/apply rejected by default")

print("Control API tests passed")
PY
