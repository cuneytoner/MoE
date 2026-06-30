from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - exercised when optional deps are absent.
    yaml = None


DEFAULT_MODES: dict[str, dict[str, Any]] = {
    "coding": {
        "mode": "coding",
        "description": "Coding and chat runtime mode with media generation stopped.",
        "generation_host": "pc1",
        "helper_host": "pc2",
        "prompt_interpreter": "disabled",
        "exclusive_gpu_mode": False,
        "grouped_capabilities": [],
        "start": ["gateway-api", "memory-api", "embed-worker", "llama-server"],
        "stop": [
            "comfyui",
            "media-api",
            "media-worker",
            "image-worker",
            "video-worker",
            "3d-worker",
            "rigging-worker",
            "animation-worker",
        ],
        "recommended_stop_for_vram": [],
        "notes": ["Default interactive coding mode."],
    },
    "image": {
        "mode": "image",
        "description": "Image generation preparation mode with PC-1 as generation host.",
        "generation_host": "pc1",
        "helper_host": "pc2",
        "prompt_interpreter": "enabled",
        "exclusive_gpu_mode": True,
        "grouped_capabilities": [],
        "start": ["comfyui", "media-api", "media-worker", "prompt-interpreter-worker"],
        "stop": ["video-worker", "3d-worker", "rigging-worker", "animation-worker"],
        "recommended_stop_for_vram": ["llama-server"],
        "notes": ["Real generation remains disabled until Milestone 26.2."],
    },
    "video": {
        "mode": "video",
        "description": "Future video generation mode.",
        "generation_host": "pc1",
        "helper_host": "pc2",
        "prompt_interpreter": "enabled",
        "exclusive_gpu_mode": True,
        "grouped_capabilities": [],
        "start": ["media-api", "media-worker", "video-worker", "prompt-interpreter-worker"],
        "stop": [
            "llama-server",
            "comfyui",
            "image-worker",
            "3d-worker",
            "rigging-worker",
            "animation-worker",
        ],
        "recommended_stop_for_vram": [],
        "notes": ["Video generation is a future milestone."],
    },
    "3d_suite": {
        "mode": "3d_suite",
        "description": "Future 3D model, rigging, and animation grouped mode.",
        "generation_host": "pc1",
        "helper_host": "pc2",
        "prompt_interpreter": "enabled",
        "exclusive_gpu_mode": True,
        "grouped_capabilities": ["3d_model", "rigging", "animation"],
        "start": [
            "media-api",
            "media-worker",
            "3d-worker",
            "rigging-worker",
            "animation-worker",
            "prompt-interpreter-worker",
        ],
        "stop": ["llama-server", "comfyui", "image-worker", "video-worker"],
        "recommended_stop_for_vram": [],
        "notes": ["Blender/3D execution is not implemented in this milestone."],
    },
    "media_off": {
        "mode": "media_off",
        "description": "Stop planned media workers and leave generation disabled.",
        "generation_host": "none",
        "helper_host": "pc2",
        "prompt_interpreter": "disabled",
        "exclusive_gpu_mode": False,
        "grouped_capabilities": [],
        "start": [],
        "stop": [
            "comfyui",
            "media-api",
            "media-worker",
            "image-worker",
            "video-worker",
            "3d-worker",
            "rigging-worker",
            "animation-worker",
            "prompt-interpreter-worker",
        ],
        "recommended_stop_for_vram": [],
        "notes": ["Media generation remains off."],
    },
}


def _normalize_modes(raw: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(raw, dict):
        return DEFAULT_MODES
    modes = raw.get("modes", raw)
    if not isinstance(modes, dict):
        return DEFAULT_MODES
    normalized: dict[str, dict[str, Any]] = {}
    for mode_id, value in modes.items():
        if isinstance(value, dict):
            item = dict(value)
            item.setdefault("mode", mode_id)
            item.setdefault("start", [])
            item.setdefault("stop", [])
            item.setdefault("recommended_stop_for_vram", [])
            item.setdefault("grouped_capabilities", [])
            item.setdefault("notes", [])
            normalized[mode_id] = item
    return normalized or DEFAULT_MODES


def load_modes(config_path: str | Path) -> dict[str, dict[str, Any]]:
    path = Path(config_path)
    if not path.is_absolute():
        path = Path.cwd() / path
    if yaml is None or not path.is_file():
        return DEFAULT_MODES
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception:
        return DEFAULT_MODES
    return _normalize_modes(data)


def build_mode_plan(mode: str, modes: dict[str, dict[str, Any]]) -> dict[str, Any] | None:
    selected = modes.get(mode)
    if selected is None:
        return None
    warnings: list[str] = []
    recommended_stop = selected.get("recommended_stop_for_vram", [])
    if recommended_stop:
        warnings.append(
            "Exclusive GPU mode may require stopping high-VRAM services: "
            + ", ".join(recommended_stop)
        )
    if selected.get("prompt_interpreter") == "enabled":
        warnings.append("prompt-interpreter-worker is a placeholder for a future milestone.")
    return {
        "status": "ok",
        "mode": selected.get("mode", mode),
        "apply_supported": False,
        "generation_host": selected.get("generation_host", "none"),
        "helper_host": selected.get("helper_host", "none"),
        "prompt_interpreter": selected.get("prompt_interpreter", "disabled"),
        "exclusive_gpu_mode": bool(selected.get("exclusive_gpu_mode", False)),
        "grouped_capabilities": selected.get("grouped_capabilities", []),
        "start": selected.get("start", []),
        "stop": selected.get("stop", []),
        "recommended_stop_for_vram": recommended_stop,
        "warnings": warnings,
    }
