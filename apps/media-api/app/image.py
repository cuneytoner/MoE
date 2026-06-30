from typing import Any

MAX_IMAGE_DIMENSION = 4096


def validate_image_metadata(metadata: dict[str, Any]) -> tuple[bool, str | None, dict[str, Any]]:
    normalized = dict(metadata)
    normalized.setdefault("engine", "disabled")

    for field in ("width", "height"):
        value = normalized.get(field)
        if value is None:
            continue
        if not isinstance(value, int) or value <= 0:
            return False, f"{field} must be a positive integer", normalized
        if value > MAX_IMAGE_DIMENSION:
            return False, f"{field} must be <= {MAX_IMAGE_DIMENSION}", normalized

    steps = normalized.get("steps")
    if steps is not None and (not isinstance(steps, int) or steps <= 0):
        return False, "steps must be a positive integer", normalized

    engine = normalized.get("engine")
    if not isinstance(engine, str):
        return False, "engine must be a string", normalized
    if engine not in {"disabled", "comfyui-placeholder", "diffusers-placeholder", "comfyui"}:
        return False, "engine must be disabled, comfyui, or a placeholder engine", normalized

    return True, None, normalized


def image_dry_run_details(job: dict[str, Any]) -> dict[str, Any]:
    metadata = job.get("metadata", {})
    return {
        "prompt_length": len(job.get("prompt", "")),
        "negative_prompt_length": len(job.get("negative_prompt", "")),
        "requested_size": {
            "width": metadata.get("width"),
            "height": metadata.get("height"),
        },
        "steps": metadata.get("steps"),
        "seed": metadata.get("seed"),
        "workflow": job.get("workflow"),
        "engine": metadata.get("engine", "disabled"),
        "model_id": metadata.get("model_id"),
        "generation_performed": False,
        "output_created": False,
        "reason": "M26.0 dry-run only",
    }
