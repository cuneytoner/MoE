from fastapi import FastAPI

from app.actions import apply_mode
from app.config import get_settings
from app.modes import build_mode_plan, load_modes
from app.schemas import ApplyResponse, HealthResponse, ModePlanRequest, ModePlanResponse
from app.status import collect_status

app = FastAPI(title="MoE Control API", version="0.1.0")


def _modes() -> dict:
    settings = get_settings()
    return load_modes(settings.mode_config_path)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        safe_actions_only=True,
        arbitrary_shell_enabled=False,
        apply_enabled=settings.allow_apply,
    )


@app.get("/control/status")
def control_status() -> dict:
    settings = get_settings()
    return collect_status(settings.runtime_path)


@app.get("/control/modes")
def control_modes() -> dict:
    return {
        "status": "ok",
        "apply_supported": False,
        "modes": _modes(),
    }


@app.post("/control/mode/plan", response_model=ModePlanResponse)
def control_mode_plan(request: ModePlanRequest) -> ModePlanResponse:
    plan = build_mode_plan(request.mode, _modes())
    if plan is None:
        return ModePlanResponse(
            status="rejected",
            mode=request.mode,
            apply_supported=False,
            generation_host="none",
            helper_host="none",
            prompt_interpreter="disabled",
            exclusive_gpu_mode=False,
            warnings=[f"unknown mode: {request.mode}"],
        )
    return ModePlanResponse(**plan)


@app.post("/control/mode/apply", response_model=ApplyResponse)
def control_mode_apply(request: ModePlanRequest) -> ApplyResponse:
    settings = get_settings()
    return ApplyResponse(**apply_mode(request.mode, _modes(), settings.allow_apply))
