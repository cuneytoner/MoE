from __future__ import annotations

import json
import os
import shutil
import socket
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx


SAFETY = {
    "read_only": True,
    "starts_services": False,
    "stops_services": False,
    "real_generation_trigger": False,
    "arbitrary_shell": False,
}


async def build_runtime_dashboard(settings: Any) -> dict[str, Any]:
    gateway = {
        "status": "ok",
        "service": "gateway-api",
        "url": "self",
        "reachable": True,
    }
    llama_server = await _check_llama_server(settings.llama_server_url)
    comfyui = await _check_http_service("comfyui", settings.comfyui_url, "/")
    pc2 = {
        "role": "helper worker node",
        "host": "192.168.50.2",
        "prompt_interpreter": await _check_http_service(
            "prompt-interpreter-worker",
            settings.pc2_prompt_interpreter_url,
            "/health",
        ),
        "nightly_learning": await _check_http_service(
            "nightly-learning-worker",
            settings.pc2_nightly_url,
            "/health",
        ),
        "research_ingestion": await _check_http_service(
            "research-ingestion-worker",
            settings.pc2_research_url,
            "/health",
        ),
        "feedback_worker": await _check_http_service(
            "feedback-worker",
            settings.pc2_feedback_url,
            "/health",
        ),
    }
    media_api = await _check_http_service("media-api", settings.media_api_url, "/health")
    media_worker = await _check_http_service("media-worker", settings.media_worker_url, "/health")
    media_jobs, job_warnings = _media_jobs(
        jobs_dir=Path(settings.media_jobs_dir),
        max_jobs=max(0, int(settings.runtime_dashboard_max_jobs)),
    )
    gpu = _gpu_status()
    pc2_system = await _pc2_system_status(settings.pc2_prompt_interpreter_url)
    system = _system_status(pc2_system)
    warnings = list(job_warnings)
    warnings.extend(_service_warnings("pc2", pc2))
    if comfyui.get("reachable") is not True:
        warnings.append(f"comfyui unavailable: {comfyui.get('detail')}")
    if llama_server.get("reachable") is not True:
        warnings.append(f"llama-server unavailable: {llama_server.get('detail')}")
    if gpu.get("available") is not True:
        warnings.append(f"gpu unavailable: {gpu.get('detail')}")
    if system["docker"].get("status") != "ok":
        warnings.append(f"docker observer unavailable: {system['docker'].get('detail')}")
    if system["pc2"].get("status") != "ok":
        warnings.append(f"pc2 system unavailable: {system['pc2'].get('detail')}")

    image_lifecycle = _image_lifecycle(
        settings=settings,
        comfyui=comfyui,
        media_api=media_api,
        media_worker=media_worker,
        prompt_interpreter=pc2["prompt_interpreter"],
    )

    return {
        "status": "ok",
        "service": "gateway-runtime-dashboard",
        "safety": SAFETY,
        "pc1": {
            "role": "main workstation / GPU runtime",
            "hostname": socket.gethostname(),
            "gateway_api": gateway,
            "llama_server": llama_server,
            "gpu": gpu,
            "comfyui": {
                **comfyui,
                "bridge_required": True,
            },
        },
        "pc2": pc2,
        "media_jobs": media_jobs,
        "image_lifecycle": image_lifecycle,
        "system": system,
        "warnings": warnings,
    }


async def _check_http_service(name: str, base_url: str, path: str) -> dict[str, Any]:
    url = f"{base_url.rstrip('/')}{path}"
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            response = await client.get(url)
        reachable = 200 <= response.status_code < 500
        data: Any
        try:
            data = response.json()
        except ValueError:
            data = None
        return {
            "status": "ok" if reachable else "unavailable",
            "service": name,
            "url": base_url,
            "reachable": reachable,
            "http_status": response.status_code,
            "data": data if isinstance(data, dict) else None,
        }
    except Exception as exc:
        return {
            "status": "unavailable",
            "service": name,
            "url": base_url,
            "reachable": False,
            "detail": exc.__class__.__name__,
        }


async def _check_llama_server(base_url: str) -> dict[str, Any]:
    service = await _check_http_service("llama-server", base_url, "/v1/models")
    models = service.get("data", {}).get("data") if isinstance(service.get("data"), dict) else None
    model = None
    if isinstance(models, list) and models:
        first = models[0]
        if isinstance(first, dict):
            model = first.get("id")
    return {
        "reachable": service.get("reachable") is True,
        "url": base_url,
        "model": model,
        "detail": service.get("detail") or f"HTTP {service.get('http_status')}",
        "status": service.get("status"),
    }


def _gpu_status() -> dict[str, Any]:
    command = [
        "nvidia-smi",
        "--query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu",
        "--format=csv,noheader,nounits",
    ]
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            timeout=3,
        )
    except FileNotFoundError:
        return {
            "available": False,
            "name": "",
            "memory_total_mb": 0,
            "memory_used_mb": 0,
            "memory_free_mb": 0,
            "utilization_gpu_percent": 0,
            "detail": "nvidia-smi not available inside gateway container",
        }
    except (subprocess.SubprocessError, OSError) as exc:
        return {
            "available": False,
            "name": "",
            "memory_total_mb": 0,
            "memory_used_mb": 0,
            "memory_free_mb": 0,
            "utilization_gpu_percent": 0,
            "detail": exc.__class__.__name__,
        }

    first_line = result.stdout.strip().splitlines()[0] if result.stdout.strip() else ""
    parts = [part.strip() for part in first_line.split(",")]
    if len(parts) < 5:
        return {
            "available": False,
            "name": "",
            "memory_total_mb": 0,
            "memory_used_mb": 0,
            "memory_free_mb": 0,
            "utilization_gpu_percent": 0,
            "detail": "unexpected nvidia-smi output",
        }
    return {
        "available": True,
        "name": parts[0],
        "memory_total_mb": _int_or_zero(parts[1]),
        "memory_used_mb": _int_or_zero(parts[2]),
        "memory_free_mb": _int_or_zero(parts[3]),
        "utilization_gpu_percent": _int_or_zero(parts[4]),
        "detail": "ok",
    }


async def _pc2_system_status(base_url: str) -> dict[str, Any]:
    service = await _check_http_service("pc2-system-status", base_url, "/system/status")
    if service.get("reachable") is not True:
        return {
            "status": "unavailable",
            "detail": service.get("detail") or f"HTTP {service.get('http_status')}",
        }
    data = service.get("data")
    if not isinstance(data, dict) or data.get("status") != "ok":
        return {
            "status": "unavailable",
            "detail": f"pc2 system endpoint returned unexpected response: HTTP {service.get('http_status')}",
        }
    return data


def _system_status(pc2_system: dict[str, Any]) -> dict[str, Any]:
    return {
        "pc1": {
            "memory": _memory_status(),
            "cpu": _cpu_status(),
            "disk": _disk_status("/"),
            "uptime": _uptime_status(),
        },
        "pc2": pc2_system,
        "docker": {
            "status": "unavailable",
            "detail": "docker observer not enabled; Docker socket is not mounted into gateway",
            "services": [],
        },
    }


def _memory_status() -> dict[str, Any]:
    values = _read_meminfo()
    total_mb = _kb_to_mb(values.get("MemTotal", 0))
    free_mb = _kb_to_mb(values.get("MemFree", 0))
    available_mb = _kb_to_mb(values.get("MemAvailable", values.get("MemFree", 0)))
    used_mb = max(0, total_mb - available_mb)
    used_percent = round((used_mb / total_mb) * 100, 1) if total_mb else 0.0
    return {
        "total_mb": total_mb,
        "used_mb": used_mb,
        "free_mb": free_mb,
        "available_mb": available_mb,
        "used_percent": used_percent,
    }


def _read_meminfo() -> dict[str, int]:
    values: dict[str, int] = {}
    try:
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            key, raw_value = line.split(":", 1)
            parts = raw_value.strip().split()
            if parts:
                values[key] = int(parts[0])
    except (OSError, ValueError):
        return {}
    return values


def _cpu_status() -> dict[str, Any]:
    try:
        parts = Path("/proc/loadavg").read_text(encoding="utf-8").split()
        load_1m = float(parts[0])
        load_5m = float(parts[1])
        load_15m = float(parts[2])
    except (OSError, ValueError, IndexError):
        load_1m = 0.0
        load_5m = 0.0
        load_15m = 0.0
    return {
        "load_1m": load_1m,
        "load_5m": load_5m,
        "load_15m": load_15m,
        "cpu_count": os.cpu_count() or 0,
    }


def _disk_status(path: str) -> dict[str, Any]:
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return {
            "path": path,
            "total_gb": 0.0,
            "used_gb": 0.0,
            "free_gb": 0.0,
            "used_percent": 0.0,
        }
    used_percent = round((usage.used / usage.total) * 100, 1) if usage.total else 0.0
    return {
        "path": path,
        "total_gb": _bytes_to_gb(usage.total),
        "used_gb": _bytes_to_gb(usage.used),
        "free_gb": _bytes_to_gb(usage.free),
        "used_percent": used_percent,
    }


def _uptime_status() -> dict[str, Any]:
    try:
        seconds = int(float(Path("/proc/uptime").read_text(encoding="utf-8").split()[0]))
    except (OSError, ValueError, IndexError):
        seconds = 0
    return {
        "seconds": seconds,
        "human": _human_duration(seconds),
    }


def _media_jobs(jobs_dir: Path, max_jobs: int) -> tuple[dict[str, Any], list[str]]:
    warnings: list[str] = []
    if not jobs_dir.exists():
        return {
            "latest_job": None,
            "latest_jobs": [],
            "jobs_dir": str(jobs_dir),
            "total_visible_jobs": 0,
        }, [f"media jobs directory is not available: {jobs_dir}"]
    if not jobs_dir.is_dir():
        return {
            "latest_job": None,
            "latest_jobs": [],
            "jobs_dir": str(jobs_dir),
            "total_visible_jobs": 0,
        }, [f"media jobs path is not a directory: {jobs_dir}"]

    try:
        paths = sorted(jobs_dir.glob("*.json"), key=lambda path: path.stat().st_mtime, reverse=True)
    except OSError as exc:
        return {
            "latest_job": None,
            "latest_jobs": [],
            "jobs_dir": str(jobs_dir),
            "total_visible_jobs": 0,
        }, [f"could not read media jobs directory: {exc.__class__.__name__}"]

    jobs = []
    for path in paths[:max_jobs]:
        job = _read_job_summary(path)
        if job is not None:
            jobs.append(job)
    if len(jobs) < min(max_jobs, len(paths)):
        warnings.append("some media job files could not be read")
    return {
        "latest_job": jobs[0] if jobs else None,
        "latest_jobs": jobs,
        "jobs_dir": str(jobs_dir),
        "total_visible_jobs": len(paths),
    }, warnings


def _read_job_summary(path: Path) -> dict[str, Any] | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        stat = path.stat()
    except (json.JSONDecodeError, OSError):
        return None
    if not isinstance(data, dict):
        return None
    return {
        "job_id": data.get("job_id"),
        "state": data.get("state"),
        "mode": data.get("mode"),
        "job_type": data.get("job_type"),
        "job_path": str(path),
        "created_at": data.get("created_at"),
        "updated_at": data.get("updated_at"),
        "modified": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
    }


def _image_lifecycle(
    *,
    settings: Any,
    comfyui: dict[str, Any],
    media_api: dict[str, Any],
    media_worker: dict[str, Any],
    prompt_interpreter: dict[str, Any],
) -> dict[str, Any]:
    dry_run_available = bool(settings.gateway_media_enabled)
    real_generation_locked = not bool(settings.gateway_media_real_allowed)
    comfyui_ready = comfyui.get("reachable") is True
    media_api_ready = media_api.get("reachable") is True
    media_worker_ready = media_worker.get("reachable") is True
    prompt_interpreter_ready = prompt_interpreter.get("reachable") is True
    if not dry_run_available:
        recommended_mode = "media_off"
        next_safe_step = "Enable dry-run media planning only when needed."
    elif media_api_ready and media_worker_ready and comfyui_ready:
        recommended_mode = "image_ready"
        next_safe_step = "Use dry-run planning first; real generation remains gated."
    elif media_api_ready and media_worker_ready:
        recommended_mode = "image_dry"
        next_safe_step = "Dry-run image jobs are available; start ComfyUI only when explicitly preparing image mode."
    else:
        recommended_mode = "coding"
        next_safe_step = "Keep coding mode or start the safe media dry-run stack manually if needed."
    return {
        "dry_run_available": dry_run_available,
        "real_generation_locked": real_generation_locked,
        "comfyui_ready": comfyui_ready,
        "media_api_ready": media_api_ready,
        "media_worker_ready": media_worker_ready,
        "prompt_interpreter_ready": prompt_interpreter_ready,
        "recommended_mode": recommended_mode,
        "next_safe_step": next_safe_step,
    }


def _service_warnings(prefix: str, data: dict[str, Any]) -> list[str]:
    warnings = []
    for key, value in data.items():
        if not isinstance(value, dict) or "reachable" not in value:
            continue
        if value.get("reachable") is not True:
            warnings.append(f"{prefix}.{key} unavailable: {value.get('detail')}")
    return warnings


def _int_or_zero(value: str) -> int:
    try:
        return int(value)
    except ValueError:
        return 0


def _kb_to_mb(value: int) -> int:
    return int(round(value / 1024))


def _bytes_to_gb(value: int) -> float:
    return round(value / (1024**3), 1)


def _human_duration(seconds: int) -> str:
    days, remainder = divmod(max(0, seconds), 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, _ = divmod(remainder, 60)
    parts = []
    if days:
        parts.append(f"{days}d")
    if hours or parts:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)
