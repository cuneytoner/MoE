#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT_PATH="${DOCKER_SUMMARY_SNAPSHOT_PATH:-${HOME}/MoE/runtime/status/docker-summary.json}"
SNAPSHOT_DIR="$(dirname "$SNAPSHOT_PATH")"

SERVICES=(
  "moe-dashboard-ui"
  "moe-gateway-api"
  "moe-memory-api"
  "moe-media-api"
  "moe-media-worker"
  "moe-embed-worker"
  "moe-postgres"
  "moe-qdrant"
  "moe-pc2-worker-prompt-interpreter-worker-1"
  "moe-pc2-worker-nightly-learning-worker-1"
  "moe-pc2-worker-research-ingestion-worker-1"
  "moe-pc2-worker-feedback-worker-1"
)

mkdir -p "$SNAPSHOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  python3 - "$SNAPSHOT_PATH" <<'PY'
import json
import sys
from datetime import UTC, datetime

path = sys.argv[1]
snapshot = {
    "status": "unavailable",
    "service": "docker-summary-snapshot",
    "read_only": True,
    "generated_at": datetime.now(UTC).isoformat(),
    "source": "host-docker-cli",
    "detail": "docker CLI unavailable on host",
    "services": [],
    "summary": {
        "total": 0,
        "running": 0,
        "healthy": 0,
        "unhealthy": 0,
        "missing": 0,
    },
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
  echo "WARN: docker CLI unavailable on host"
  echo "Wrote unavailable Docker summary snapshot: $SNAPSHOT_PATH"
  exit 0
fi

python3 - "$SNAPSHOT_PATH" "${SERVICES[@]}" <<'PY'
import json
import subprocess
import sys
from datetime import UTC, datetime
from typing import Any

snapshot_path = sys.argv[1]
service_names = sys.argv[2:]


def inspect_container(name: str) -> dict[str, Any]:
    result = subprocess.run(
        ["docker", "inspect", name],
        check=False,
        capture_output=True,
        text=True,
        timeout=5,
    )
    if result.returncode != 0:
        return {
            "name": name,
            "status": "missing",
            "health": "unknown",
            "ports": "",
            "image": "",
        }

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {
            "name": name,
            "status": "unknown",
            "health": "unknown",
            "ports": "",
            "image": "",
        }

    data = payload[0] if payload else {}
    state = data.get("State") if isinstance(data, dict) else {}
    config = data.get("Config") if isinstance(data, dict) else {}
    network = data.get("NetworkSettings") if isinstance(data, dict) else {}
    health = "none"
    if isinstance(state, dict) and isinstance(state.get("Health"), dict):
        health = str(state["Health"].get("Status") or "unknown")

    return {
        "name": name,
        "status": str(state.get("Status") or "unknown") if isinstance(state, dict) else "unknown",
        "health": health,
        "ports": format_ports(network.get("Ports") if isinstance(network, dict) else None),
        "image": str(config.get("Image") or "") if isinstance(config, dict) else "",
    }


def format_ports(ports: Any) -> str:
    if not isinstance(ports, dict) or not ports:
        return ""
    parts = []
    for container_port, bindings in sorted(ports.items()):
        if not bindings:
            parts.append(str(container_port))
            continue
        if isinstance(bindings, list):
            for binding in bindings:
                if isinstance(binding, dict):
                    host_ip = binding.get("HostIp") or ""
                    host_port = binding.get("HostPort") or ""
                    parts.append(f"{host_ip}:{host_port}->{container_port}")
    return ", ".join(parts)


services = [inspect_container(name) for name in service_names]
summary = {
    "total": len(services),
    "running": sum(1 for service in services if service["status"] == "running"),
    "healthy": sum(1 for service in services if service["health"] == "healthy"),
    "unhealthy": sum(1 for service in services if service["health"] == "unhealthy"),
    "missing": sum(1 for service in services if service["status"] == "missing"),
}
snapshot = {
    "status": "ok",
    "service": "docker-summary-snapshot",
    "read_only": True,
    "generated_at": datetime.now(UTC).isoformat(),
    "source": "host-docker-cli",
    "services": services,
    "summary": summary,
}
with open(snapshot_path, "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY

echo "Wrote Docker summary snapshot: $SNAPSHOT_PATH"
