from fastapi import FastAPI

from app.config import get_settings
from app.interpreter import interpret_prompt
from app.schemas import BatchInterpretRequest, HealthResponse, InterpretRequest

app = FastAPI(title="MoE Prompt Interpreter Worker", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        mode=settings.mode,
        model_enabled=settings.model_enabled,
        generation_enabled=settings.generation_enabled,
        dry_run_default=settings.default_mode == "dry_run",
    )


@app.post("/interpret")
def interpret(request: InterpretRequest) -> dict:
    if request.mode != "dry_run":
        return {
            "status": "rejected",
            "reason": "only dry_run mode is supported",
            "model_called": False,
            "generation_called": False,
        }
    return interpret_prompt(request.prompt, request.target_mode, request.style)


@app.post("/interpret/batch")
def interpret_batch(request: BatchInterpretRequest) -> dict:
    results = []
    for item in request.items:
        if item.mode != "dry_run":
            results.append(
                {
                    "status": "rejected",
                    "reason": "only dry_run mode is supported",
                    "model_called": False,
                    "generation_called": False,
                }
            )
        else:
            results.append(interpret_prompt(item.prompt, item.target_mode, item.style))
    return {"status": "ok", "count": len(results), "results": results}
