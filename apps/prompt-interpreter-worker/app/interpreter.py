from app.presets import build_job_spec


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
]
VIDEO_KEYWORDS = ["video", "animatic", "shot", "kamera hareketi", "sahne", "clip", "i2v"]
MODEL_3D_KEYWORDS = ["3d model", "mesh", "obj", "glb", "modelle", "low poly", "turntable"]
RIGGING_KEYWORDS = ["rig", "rigging", "skeleton", "bone", "armature", "kemik"]
ANIMATION_KEYWORDS = ["animation", "animasyon", "hareket", "timeline", "keyframe"]

TARGET_MODE_MAP = {
    "image": "image",
    "video": "video",
    "3d_model": "3d_model",
    "rigging": "rigging",
    "animation": "animation",
    "3d_suite": "3d_suite",
}


def _matches(text: str, keywords: list[str]) -> list[str]:
    return [keyword for keyword in keywords if keyword in text]


def classify_prompt(prompt: str, target_mode: str = "auto") -> dict:
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


def interpret_prompt(prompt: str, target_mode: str, style: str) -> dict:
    classification = classify_prompt(prompt, target_mode)
    job_spec = build_job_spec(classification["intent"], prompt)
    metadata = job_spec.setdefault("metadata", {})
    metadata["style"] = style
    warnings: list[str] = []
    if classification["intent"] == "unknown":
        warnings.append("No confident media intent detected; job_spec is informational only.")
    warnings.append("Dry-run only. No model, ComfyUI, or generation engine was called.")
    return {
        "status": "ok",
        "classification": classification,
        "job_spec": job_spec,
        "warnings": warnings,
    }
