import json
import shutil
import time
import urllib.error
import urllib.request
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


def check_health(comfyui_url: str) -> tuple[bool, str | None]:
    health_url = f"{comfyui_url.rstrip('/')}/"
    try:
        with urllib.request.urlopen(health_url, timeout=5):
            return True, None
    except (OSError, urllib.error.URLError) as exc:
        return False, f"url={health_url} exception={exc.__class__.__name__}"


def submit_prompt(comfyui_url: str, workflow: dict[str, Any]) -> dict[str, Any]:
    payload = json.dumps({"prompt": workflow}).encode("utf-8")
    request = urllib.request.Request(
        f"{comfyui_url.rstrip('/')}/prompt",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
        prompt_url = f"{comfyui_url.rstrip('/')}/prompt"
        raise RuntimeError(f"ComfyUI prompt submit failed: url={prompt_url} exception={exc.__class__.__name__}") from exc


def discover_and_copy_outputs(
    source_dirs: list[Path],
    target_dir: Path,
    marker: Path,
    timeout_seconds: int = 120,
) -> list[str]:
    target_dir.mkdir(parents=True, exist_ok=True)
    for _ in range(timeout_seconds):
        found: list[Path] = []
        for source_dir in source_dirs:
            if not source_dir.exists():
                continue
            for path in source_dir.rglob("*"):
                if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
                    try:
                        if path.stat().st_mtime > marker.stat().st_mtime:
                            found.append(path)
                    except OSError:
                        continue
        if found:
            outputs: list[str] = []
            for path in sorted(found):
                target = target_dir / path.name
                if path.resolve() != target.resolve():
                    if target.exists():
                        stamp = datetime.now(UTC).strftime("%Y%m%d%H%M%S")
                        target = target_dir / f"{target.stem}-{stamp}{target.suffix}"
                    shutil.copy2(path, target)
                outputs.append(str(target.resolve()))
            return outputs
        time.sleep(1)
    return []


def build_flux_workflow(job: dict[str, Any], filename_prefix: str) -> dict[str, Any]:
    metadata = job.get("metadata", {})
    width = int(metadata.get("width", 512))
    height = int(metadata.get("height", 512))
    steps = int(metadata.get("steps", 4))
    seed = int(metadata.get("seed", -1))
    if seed < 0:
        seed = int(time.time())
    prompt = job.get("prompt", "")
    negative_prompt = job.get("negative_prompt", "")
    return {
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": 1.0,
                "sampler_name": "euler",
                "scheduler": "simple",
                "denoise": 1.0,
                "model": ["10", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0],
            },
        },
        "4": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["11", 0]}},
        "5": {
            "class_type": "EmptyLatentImage",
            "inputs": {"width": width, "height": height, "batch_size": 1},
        },
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["12", 0]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": negative_prompt, "clip": ["12", 0]}},
        "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": filename_prefix, "images": ["4", 0]}},
        "10": {"class_type": "UNETLoader", "inputs": {"unet_name": "flux1-schnell.safetensors", "weight_dtype": "default"}},
        "11": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "12": {
            "class_type": "DualCLIPLoader",
            "inputs": {
                "clip_name1": "clip_l.safetensors",
                "clip_name2": "t5xxl_fp8_e4m3fn.safetensors",
                "type": "flux",
            },
        },
    }
