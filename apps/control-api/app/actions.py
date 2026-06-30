from app.modes import build_mode_plan


def apply_mode(mode: str, modes: dict, allow_apply: bool) -> dict:
    plan = build_mode_plan(mode, modes)
    if plan is None:
        return {"status": "rejected", "reason": f"unknown mode: {mode}"}
    if not allow_apply:
        return {
            "status": "rejected",
            "mode": mode,
            "apply_supported": False,
            "reason": "CONTROL_ALLOW_APPLY is false; M26.1.5 is plan-only by default.",
            "plan": plan,
        }
    return {
        "status": "rejected",
        "mode": mode,
        "apply_supported": False,
        "reason": "mode apply remains future-gated; arbitrary shell commands are not supported.",
        "plan": plan,
    }
