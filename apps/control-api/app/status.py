from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen


KNOWN_HTTP_SERVICES = {
    "llama-server": "http://127.0.0.1:8000/v1/models",
    "gateway-api": "http://127.0.0.1:8100/gateway/health",
    "memory-api": "http://127.0.0.1:8101/health",
    "embed-worker": "http://127.0.0.1:8102/health",
    "comfyui": "http://127.0.0.1:8188/",
    "nightly-learning-worker": "http://127.0.0.1:8200/health",
    "research-ingestion-worker": "http://127.0.0.1:8210/health",
    "feedback-worker": "http://127.0.0.1:8220/health",
    "prompt-interpreter-worker": "http://127.0.0.1:8230/health",
    "media-api": "http://127.0.0.1:8300/health",
    "media-worker": "http://127.0.0.1:8310/health",
}

FUTURE_SERVICES = [
    "image-worker",
    "video-worker",
    "3d-worker",
    "rigging-worker",
    "animation-worker",
]

PID_FILES = {
    "llama-server": "model-runtime.pid",
    "comfyui": "media-engines/comfyui/comfyui.pid",
}


def _http_status(url: str) -> dict[str, str | int | bool]:
    request = Request(url, method="GET")
    try:
        with urlopen(request, timeout=0.5) as response:
            return {
                "kind": "http",
                "url": url,
                "reachable": True,
                "status_code": response.status,
            }
    except (OSError, URLError) as exc:
        return {
            "kind": "http",
            "url": url,
            "reachable": False,
            "error": exc.__class__.__name__,
        }


def _pid_status(runtime_root: Path, service: str) -> dict[str, str | bool]:
    relative = PID_FILES.get(service)
    if relative is None:
        return {"kind": "pid", "known_pid_file": False}
    path = runtime_root / relative
    if not path.is_file():
        return {"kind": "pid", "known_pid_file": True, "pid_file": str(path), "present": False}
    pid = path.read_text(encoding="utf-8").strip()
    return {
        "kind": "pid",
        "known_pid_file": True,
        "pid_file": str(path),
        "present": True,
        "pid": pid,
    }


def collect_status(runtime_root: Path) -> dict:
    services: dict[str, dict] = {}
    for service, url in KNOWN_HTTP_SERVICES.items():
        services[service] = {
            "service": service,
            "http": _http_status(url),
            "pid": _pid_status(runtime_root, service),
        }
    for service in FUTURE_SERVICES:
        services[service] = {
            "service": service,
            "future": True,
            "implemented": False,
            "http": {"kind": "http", "reachable": False, "reason": "future placeholder"},
            "pid": {"kind": "pid", "known_pid_file": False},
        }
    services["postgres"] = {
        "service": "postgres",
        "kind": "container_or_external",
        "read_only_status": "not_probed_without_docker",
    }
    services["qdrant"] = {
        "service": "qdrant",
        "http": _http_status("http://127.0.0.1:6333/"),
    }
    return {
        "status": "ok",
        "read_only": True,
        "host_roles": {
            "pc1": ["generation_host", "heavy GPU jobs", "llama-server", "ComfyUI"],
            "pc2": ["helper_host", "job queue / metadata", "feedback and reports"],
        },
        "services": services,
    }
