from copy import deepcopy


PRESETS: dict[str, dict] = {
    "image": {
        "job_type": "image",
        "workflow": "image_default",
        "metadata": {
            "width": 1024,
            "height": 1024,
            "steps": 4,
            "engine": "disabled",
        },
    },
    "video": {
        "job_type": "video",
        "workflow": "video_default",
        "metadata": {
            "duration_seconds": 4,
            "fps": 12,
            "engine": "disabled",
        },
    },
    "3d_model": {
        "job_type": "3d",
        "workflow": "3d_default",
        "metadata": {
            "format": "glb",
            "engine": "disabled",
        },
    },
    "rigging": {
        "job_type": "rigging",
        "workflow": "rigging_default",
        "metadata": {
            "engine": "disabled",
        },
    },
    "animation": {
        "job_type": "animation",
        "workflow": "animation_default",
        "metadata": {
            "engine": "disabled",
        },
    },
    "3d_suite": {
        "job_type": "3d",
        "workflow": "3d_suite_default",
        "metadata": {
            "grouped_capabilities": ["3d_model", "rigging", "animation"],
            "engine": "disabled",
        },
    },
    "unknown": {
        "job_type": "unknown",
        "workflow": "unknown_default",
        "metadata": {
            "engine": "disabled",
        },
    },
}


def build_job_spec(intent: str, prompt: str) -> dict:
    preset = deepcopy(PRESETS.get(intent, PRESETS["unknown"]))
    preset.update(
        {
            "mode": "dry_run",
            "prompt": prompt,
        }
    )
    metadata = preset.setdefault("metadata", {})
    metadata.update(
        {
            "generation_host": "pc1",
            "helper_host": "pc2",
            "source": "prompt-interpreter-worker",
        }
    )
    return preset
