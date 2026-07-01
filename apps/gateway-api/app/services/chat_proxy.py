from typing import Any

import httpx

from app.config import Settings
from app.models.gateway import GatewayChatProxyRequest


class GatewayChatProxyUnavailable(RuntimeError):
    pass


def choose_chat_model(settings: Settings, active_model: str | None = None) -> str:
    """Forward to the current runtime/default; never treat user input as a model path."""
    if active_model:
        return active_model
    return settings.default_model


async def proxy_chat_to_llama(
    request: GatewayChatProxyRequest,
    settings: Settings,
) -> dict[str, Any]:
    base_url = settings.llama_server_base_url.rstrip("/")
    active_model = await fetch_active_model(settings)
    model = choose_chat_model(settings=settings, active_model=active_model)
    payload = {
        "model": model,
        "messages": [
            {"role": message.role, "content": message.content}
            for message in request.messages
        ],
        "temperature": request.temperature,
        "max_tokens": request.max_tokens,
        "stream": False,
    }

    try:
        async with httpx.AsyncClient(timeout=settings.gateway_chat_timeout_seconds) as client:
            response = await client.post(
                f"{base_url}/v1/chat/completions",
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
    except Exception as exc:
        raise GatewayChatProxyUnavailable(
            f"llama-server unavailable: {exc.__class__.__name__}: {exc}"
        ) from exc

    return {
        "model": data.get("model") if isinstance(data.get("model"), str) else model,
        "content": _extract_content(data),
        "raw": _minimal_raw(data),
        "active_model": active_model,
    }


async def fetch_active_model(settings: Settings) -> str | None:
    base_url = settings.llama_server_base_url.rstrip("/")
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{base_url}/v1/models")
            response.raise_for_status()
            data = response.json()
    except Exception:
        return None

    models = data.get("data") if isinstance(data, dict) else data
    if not isinstance(models, list) or not models:
        return None
    first = models[0]
    if not isinstance(first, dict):
        return str(first)
    model_id = first.get("id")
    return model_id if isinstance(model_id, str) and model_id else None


def _extract_content(response: dict[str, Any]) -> str:
    choices = response.get("choices")
    if isinstance(choices, list) and choices:
        first = choices[0]
        if isinstance(first, dict):
            message = first.get("message")
            if isinstance(message, dict):
                content = message.get("content")
                if isinstance(content, str):
                    return content
            text = first.get("text")
            if isinstance(text, str):
                return text
    return ""


def _minimal_raw(response: dict[str, Any]) -> dict[str, Any]:
    raw: dict[str, Any] = {}
    for key in ("id", "object", "created", "model", "usage"):
        value = response.get(key)
        if value is not None:
            raw[key] = value

    choices = response.get("choices")
    if isinstance(choices, list):
        raw["choices"] = [
            {
                key: choice.get(key)
                for key in ("index", "finish_reason")
                if isinstance(choice, dict) and choice.get(key) is not None
            }
            for choice in choices[:1]
            if isinstance(choice, dict)
        ]
    return raw
