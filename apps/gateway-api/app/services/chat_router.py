from dataclasses import dataclass

from app.models.gateway import GatewayChatProxyRequest
from app.services.model_mapping import ModelMapping


MODEL_TARGETS = {
    "fast_code": "qwen-coder-14b-fast",
    "deep_code": "qwen-coder-32b-main",
    "review_debug": "deepseek-coder-lite",
    "architecture": "qwen-coder-32b-main",
    "general": "qwen-coder-14b-fast",
}

KEYWORDS = {
    "fast_code": {
        "code",
        "function",
        "class",
        "bug",
        "error",
        "stacktrace",
        "typescript",
        "python",
        "fastapi",
        "docker",
        "llama.cpp",
        "config",
        "yaml",
    },
    "deep_code": {
        "refactor",
        "large file",
        "complex",
        "multi-file",
        "multifile",
        "implement milestone",
    },
    "review_debug": {
        "traceback",
        "exception",
        "failing test",
        "regression",
        "debug",
        "logs",
        "error output",
    },
    "architecture": {
        "roadmap",
        "architecture",
        "design",
        "module",
        "service",
        "schema",
        "system",
    },
}

PRIORITY = ["review_debug", "architecture", "deep_code", "fast_code", "general"]


@dataclass(frozen=True)
class ChatRoute:
    intent: str
    confidence: float
    selected_model_id: str
    selected_model_path: str | None
    mode: str
    reasons: list[str]
    user_model_preference: str | None = None

    def to_response(
        self,
        active_model: str | None,
    ) -> dict[str, object]:
        return {
            "intent": self.intent,
            "confidence": self.confidence,
            "selected_model_id": self.selected_model_id,
            "selected_model_path": self.selected_model_path,
            "active_model": active_model,
            "active_model_matches": _model_matches(
                active_model=active_model,
                selected_model_path=self.selected_model_path,
            ),
            "mode": self.mode,
            "reasons": self.reasons,
            "user_model_preference": self.user_model_preference,
        }


def classify_chat_intent(
    request: GatewayChatProxyRequest,
    mapping: ModelMapping,
) -> ChatRoute:
    if request.routing == "off":
        selected_model_id = MODEL_TARGETS["general"]
        return ChatRoute(
            intent="general",
            confidence=0.0,
            selected_model_id=selected_model_id,
            selected_model_path=mapping.runtime_id(selected_model_id),
            mode="disabled",
            reasons=["routing=off; heuristic model selection skipped"],
            user_model_preference=request.model,
        )

    text = _combined_text(request)
    matches: dict[str, list[str]] = {}
    for intent, keywords in KEYWORDS.items():
        intent_matches = [keyword for keyword in sorted(keywords) if keyword in text]
        if intent_matches:
            matches[intent] = intent_matches

    intent = _select_intent(matches)
    selected_model_id = MODEL_TARGETS[intent]
    reasons = _reasons(intent=intent, matches=matches, request=request)
    confidence = _confidence(intent=intent, matches=matches)
    return ChatRoute(
        intent=intent,
        confidence=confidence,
        selected_model_id=selected_model_id,
        selected_model_path=mapping.runtime_id(selected_model_id),
        mode="advisory",
        reasons=reasons,
        user_model_preference=request.model,
    )


def _combined_text(request: GatewayChatProxyRequest) -> str:
    return "\n".join(message.content.lower() for message in request.messages)


def _select_intent(matches: dict[str, list[str]]) -> str:
    if "architecture" in matches and "deep_code" in matches:
        return "architecture"

    for intent in PRIORITY:
        if intent in matches:
            return intent
    return "general"


def _confidence(intent: str, matches: dict[str, list[str]]) -> float:
    if intent == "general" and not matches:
        return 0.35

    count = len(matches.get(intent, []))
    related_count = sum(len(values) for values in matches.values())
    score = 0.45 + (count * 0.12) + min(related_count, 6) * 0.03
    return round(min(score, 0.95), 2)


def _reasons(
    intent: str,
    matches: dict[str, list[str]],
    request: GatewayChatProxyRequest,
) -> list[str]:
    reasons = []
    for matched_intent, keywords in sorted(matches.items()):
        reasons.append(
            f"{matched_intent} keywords matched: {', '.join(keywords[:6])}"
        )
    if request.model:
        reasons.append("request.model treated as advisory preference only")
    if not reasons:
        reasons.append("no specific routing keywords matched; using general default")
    reasons.append(f"selected {MODEL_TARGETS[intent]} for {intent}")
    return reasons


def _model_matches(active_model: str | None, selected_model_path: str | None) -> bool:
    if not active_model or not selected_model_path:
        return False
    return active_model == selected_model_path
