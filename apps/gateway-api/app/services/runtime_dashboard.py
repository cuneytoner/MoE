from __future__ import annotations

import json
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
    warnings = list(job_warnings)
    warnings.extend(_service_warnings("pc2", pc2))
    if comfyui.get("reachable") is not True:
        warnings.append(f"comfyui unavailable: {comfyui.get('detail')}")
    if llama_server.get("reachable") is not True:
        warnings.append(f"llama-server unavailable: {llama_server.get('detail')}")
    if gpu.get("available") is not True:
        warnings.append(f"gpu unavailable: {gpu.get('detail')}")

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
    except (FileNotFoundError, subprocess.SubprocessError, OSError) as exc:
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
