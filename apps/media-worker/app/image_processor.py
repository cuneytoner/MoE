from typing import Any


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
