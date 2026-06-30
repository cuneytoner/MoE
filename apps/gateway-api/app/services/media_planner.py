from __future__ import annotations

from copy import deepcopy
from typing import Any


IMAGE_KEYWORDS = [
    "image",
    "görsel",
    "resim",
    "render",
    "concept",
    "poster",
    "fotoğraf",
    "realistic",
    "flux",
    "photo",
]
VIDEO_KEYWORDS = ["video", "animatic", "shot", "kamera hareketi", "sahne", "clip", "i2v"]
MODEL_3D_KEYWORDS = ["3d model", "mesh", "obj", "glb", "modelle", "low poly", "turntable"]
RIGGING_KEYWORDS = ["rig", "rigging", "skeleton", "bone", "armature", "kemik"]
ANIMATION_KEYWORDS = ["animation", "animasyon", "hareket", "timeline", "keyframe"]

PRESETS: dict[str, dict[str, Any]] = {
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

TARGET_MODE_MAP = {
    "image": "image",
    "video": "video",
    "3d_model": "3d_model",
    "rigging": "rigging",
    "animation": "animation",
    "3d_suite": "3d_suite",
}


def local_media_plan(prompt: str, target_mode: str, style: str) -> dict[str, Any]:
    classification = classify_prompt(prompt, target_mode)
    job_spec = build_job_spec(classification["intent"], prompt, style)
    warnings = ["Prompt Interpreter Worker unavailable; used Gateway local fallback."]
    if classification["intent"] == "unknown":
        warnings.append("No confident media intent detected; job_spec is informational only.")
    warnings.append("Plan only. No Media API job or generation engine was called.")
    return {
        "status": "ok",
        "classification": classification,
        "job_spec": job_spec,
        "warnings": warnings,
    }


def classify_prompt(prompt: str, target_mode: str = "auto") -> dict[str, Any]:
    if target_mode in TARGET_MODE_MAP:
        return {
            "intent": TARGET_MODE_MAP[target_mode],
            "confidence": 1.0,
            "reason": f"explicit target_mode={target_mode}",
        }

    text = prompt.lower()
    image_matches = _matches(text, IMAGE_KEYWORDS)
    video_matches = _matches(text, VIDEO_KEYWORDS)
    model_matches = _matches(text, MODEL_3D_KEYWORDS)
    rig_matches = _matches(text, RIGGING_KEYWORDS)
    animation_matches = _matches(text, ANIMATION_KEYWORDS)

    has_3d = bool(model_matches) or "3d" in text
    if has_3d and (rig_matches or animation_matches):
        matched = model_matches + rig_matches + animation_matches
        return {
            "intent": "3d_suite",
            "confidence": 0.9,
            "reason": "matched 3D plus rigging or animation keywords: " + ", ".join(matched),
        }

    scores = {
        "image": image_matches,
        "video": video_matches,
        "3d_model": model_matches,
        "rigging": rig_matches,
        "animation": animation_matches,
    }
    best_intent = "unknown"
    best_matches: list[str] = []
    for intent, matches in scores.items():
        if len(matches) > len(best_matches):
            best_intent = intent
            best_matches = matches

    if not best_matches:
        return {"intent": "unknown", "confidence": 0.0, "reason": "no media keywords matched"}

    confidence = min(0.95, 0.55 + (0.1 * len(best_matches)))
    return {
        "intent": best_intent,
        "confidence": round(confidence, 2),
        "reason": f"matched {best_intent} keywords: " + ", ".join(best_matches),
    }


def build_job_spec(prompt_intent: str, prompt: str, style: str) -> dict[str, Any]:
    preset = deepcopy(PRESETS.get(prompt_intent, PRESETS["unknown"]))
    preset.update({"mode": "dry_run", "prompt": prompt})
    metadata = preset.setdefault("metadata", {})
    metadata.update(
        {
            "generation_host": "pc1",
            "helper_host": "pc2",
            "source": "gateway-local-fallback",
            "style": style,
        }
    )
    return preset


def _matches(text: str, keywords: list[str]) -> list[str]:
    return [keyword for keyword in keywords if keyword in text]
