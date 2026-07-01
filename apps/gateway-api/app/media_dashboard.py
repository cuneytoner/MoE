from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


async def build_media_dashboard(settings: Any) -> dict[str, Any]:
    services = {
        "gateway": {
            "status": "ok",
            "service": "gateway-api",
            "url": "self",
        },
        "media_api": await _check_service(
            name="media-api",
            base_url=settings.media_api_url,
            path="/health",
        ),
        "media_worker": await _check_service(
            name="media-worker",
            base_url=settings.media_worker_url,
            path="/health",
        ),
        "prompt_interpreter": await _check_service(
            name="prompt-interpreter-worker",
            base_url=settings.prompt_interpreter_url,
            path="/health",
        ),
        "control_api": await _check_service(
            name="control-api",
            base_url=settings.control_api_url,
            path="/health",
        ),
        "comfyui": await _check_service(
            name="comfyui",
            base_url=settings.comfyui_url,
            path="/",
        ),
    }
    latest_images, image_warnings = _latest_images(
        outputs_dir=Path(settings.media_outputs_dir),
        max_images=max(0, int(settings.media_dashboard_max_images)),
    )
    warnings = image_warnings
    for name, service in services.items():
        if name == "gateway":
            continue
        if service.get("reachable") is not True:
            warnings.append(f"{name} unreachable: {service.get('detail')}")

    return {
        "status": "ok",
        "service": "gateway-media-dashboard",
        "safety": {
            "read_only": True,
            "starts_services": False,
            "stops_services": False,
            "real_generation_trigger": False,
            "arbitrary_shell": False,
        },
        "services": services,
        "gates": {
            "gateway_media_enabled": settings.gateway_media_enabled,
            "gateway_real_allowed": settings.gateway_media_real_allowed,
            "media_real_generation_enabled": _media_real_generation_enabled(services["media_api"]),
            "media_dashboard_enabled": settings.media_dashboard_enabled,
            "comfyui_external_bridge_required_for_docker": True,
        },
        "latest_images": latest_images,
        "mode_hints": {
            "coding": "Coding mode keeps media generation disabled so chat and coding resources stay predictable.",
            "image": "Image mode prepares Media API, Media Worker, ComfyUI, and Prompt Interpreter, but generation still needs explicit gates.",
            "media_off": "Media-off mode should keep media generation workers stopped or disabled.",
        },
        "safe_commands": {
            "image_mode_prepare": [
                "make comfyui-health",
                "make check-flux-schnell-models",
                "make comfyui-vram-status",
            ],
            "real_generation_enable": [
                "COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up",
                "MEDIA_REAL_GENERATION_ENABLED=true docker compose -f infra/docker/docker-compose.yml --profile media up -d --build media-api media-worker",
            ],
            "safe_shutdown": [
                "MEDIA_REAL_GENERATION_ENABLED=false docker compose -f infra/docker/docker-compose.yml --profile media up -d --build media-api media-worker",
                "make comfyui-down",
            ],
        },
        "warnings": warnings,
    }


async def _check_service(name: str, base_url: str, path: str) -> dict[str, Any]:
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


def _latest_images(outputs_dir: Path, max_images: int) -> tuple[list[dict[str, Any]], list[str]]:
    warnings: list[str] = []
    images: list[Path] = []
    if not outputs_dir.exists():
        return [], [f"media outputs directory is not available: {outputs_dir}"]
    if not outputs_dir.is_dir():
        return [], [f"media outputs path is not a directory: {outputs_dir}"]

    try:
        for path in outputs_dir.rglob("*"):
            if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
                images.append(path)
    except OSError as exc:
        return [], [f"could not read media outputs directory: {exc.__class__.__name__}"]

    def sort_key(path: Path) -> float:
        try:
            return path.stat().st_mtime
        except OSError:
            return 0.0

    results = []
    for path in sorted(images, key=sort_key, reverse=True)[:max_images]:
        try:
            stat = path.stat()
        except OSError:
            continue
        results.append(
            {
                "path": str(path),
                "name": path.name,
                "modified": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
                "size_bytes": stat.st_size,
            }
        )
    return results, warnings


def _media_real_generation_enabled(media_api_service: dict[str, Any]) -> bool:
    data = media_api_service.get("data")
    if not isinstance(data, dict):
        return False
    return bool(data.get("real_generation_enabled"))
