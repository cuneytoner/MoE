from dataclasses import dataclass

import httpx

from app.config import Settings
from app.models.gateway import GatewayChatProxyMessage, GatewayChatProxyRequest


@dataclass(frozen=True)
class MemoryInjectionResult:
    request: GatewayChatProxyRequest
    metadata: dict[str, object]


async def build_memory_injected_request(
    request: GatewayChatProxyRequest,
    settings: Settings,
) -> MemoryInjectionResult:
    limit = min(max(request.memory_limit, 1), 8)
    metadata: dict[str, object] = {
        "mode": request.memory,
        "status": "disabled",
        "injected": False,
        "result_count": 0,
        "limit": limit,
    }
    if request.memory == "off":
        metadata["detail"] = "memory=off"
        return MemoryInjectionResult(request=request, metadata=metadata)

    query = _latest_user_message(request)
    if not query:
        metadata.update(
            {
                "status": "empty",
                "detail": "no user message available for memory search",
            }
        )
        return MemoryInjectionResult(request=request, metadata=metadata)

    try:
        response = await _search_memory(
            url=settings.memory_search_url,
            query=query,
            limit=limit,
        )
    except Exception as exc:
        metadata.update(
            {
                "status": "unavailable",
                "detail": f"memory search unavailable: {exc.__class__.__name__}: {exc}",
            }
        )
        return MemoryInjectionResult(request=request, metadata=metadata)

    if not isinstance(response.get("results"), list):
        metadata.update(
            {
                "status": "error",
                "detail": "memory search response missing results array",
            }
        )
        return MemoryInjectionResult(request=request, metadata=metadata)

    results = _extract_text_results(response, limit=limit)
    metadata["result_count"] = len(results)
    if not results:
        metadata.update(
            {
                "status": "empty",
                "detail": "memory search returned no usable text results",
            }
        )
        return MemoryInjectionResult(request=request, metadata=metadata)

    context = _format_memory_context(
        results=results,
        max_chars=settings.gateway_memory_context_max_chars,
    )
    if not context:
        metadata.update(
            {
                "status": "empty",
                "result_count": 0,
                "detail": "memory results were empty after formatting",
            }
        )
        return MemoryInjectionResult(request=request, metadata=metadata)

    metadata.update(
        {
            "status": "ok",
            "injected": True,
            "detail": "bounded memory context injected",
        }
    )
    injected_messages = [
        GatewayChatProxyMessage(role="system", content=context),
        *request.messages,
    ]
    injected_request = request.model_copy(
        update={
            "messages": injected_messages,
            "memory_limit": limit,
        }
    )
    return MemoryInjectionResult(request=injected_request, metadata=metadata)


async def _search_memory(url: str, query: str, limit: int) -> dict[str, object]:
    async with httpx.AsyncClient(timeout=5) as client:
        response = await client.post(url, json={"query": query, "limit": limit})
        response.raise_for_status()
        data = response.json()
    if not isinstance(data, dict):
        raise ValueError("memory search returned non-object response")
    return data


def _latest_user_message(request: GatewayChatProxyRequest) -> str:
    for message in reversed(request.messages):
        if message.role == "user" and message.content.strip():
            return message.content.strip()
    return ""


def _extract_text_results(
    response: dict[str, object],
    limit: int,
) -> list[str]:
    raw_results = response.get("results")
    if not isinstance(raw_results, list):
        return []

    texts: list[str] = []
    for item in raw_results:
        if len(texts) >= limit:
            break
        if not isinstance(item, dict):
            continue
        text = item.get("text") or item.get("content") or item.get("memory")
        if not isinstance(text, str):
            continue
        cleaned = " ".join(text.split())
        if cleaned:
            texts.append(cleaned)
    return texts


def _format_memory_context(results: list[str], max_chars: int) -> str:
    max_chars = max(500, max_chars)
    header = "Relevant local memory context:"
    footer = "Use this only if relevant. Do not claim memory if irrelevant."
    lines = [header]
    for index, text in enumerate(results, start=1):
        candidate = f"[{index}] {text}"
        tentative = "\n".join([*lines, candidate, footer])
        if len(tentative) <= max_chars:
            lines.append(candidate)
            continue

        remaining = max_chars - len("\n".join([*lines, footer])) - len(f"\n[{index}] ...")
        if remaining <= 40:
            break
        lines.append(f"[{index}] {text[:remaining].rstrip()}...")
        break

    if len(lines) == 1:
        return ""
    lines.append(footer)
    return "\n".join(lines)
