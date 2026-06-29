from dataclasses import dataclass


@dataclass(frozen=True)
class RouteDecision:
    intent: str
    confidence: float
    use_memory_recommended: bool
    reason: str
    signals: dict[str, object]


KEYWORDS: dict[str, list[str]] = {
    "code": [
        "code",
        "bug",
        "traceback",
        "error",
        "stack trace",
        "function",
        "class",
        "test",
        "pytest",
        "fastapi",
        "react",
        "typescript",
        "prisma",
        "dockerfile",
        "kod",
        "hata",
        "fonksiyon",
        "sinif",
        "sınıf",
        "duzelt",
        "düzelt",
        "refactor",
        "derleme",
    ],
    "memory": [
        "remember",
        "recall",
        "what did we",
        "previous",
        "memory",
        "hatirla",
        "hatırla",
        "hafiza",
        "hafıza",
        "daha once",
        "daha önce",
        "gecen",
        "geçen",
        "ne demistik",
        "ne demiştik",
        "kayit",
        "kayıt",
    ],
    "review": [
        "review",
        "inspect",
        "analyze",
        "architecture",
        "security",
        "performance",
        "incele",
        "analiz et",
        "mimari",
        "guvenlik",
        "güvenlik",
        "performans",
        "kontrol et",
    ],
    "ops": [
        "docker",
        "compose",
        "container",
        "linux",
        "ubuntu",
        "pop-os",
        "ssh",
        "network",
        "port",
        "systemd",
        "logs",
        "deploy",
        "runtime",
        "kurulum",
        "servis",
        "log",
        "ag",
        "ağ",
        "dagitim",
        "dağıtım",
        "sunucu",
        "terminal",
    ],
}

REASONS = {
    "chat": "No strong routing keywords matched",
    "code": "Matched coding/debugging terms",
    "memory": "Matched memory/recall terms",
    "review": "Matched review/analysis terms",
    "ops": "Matched operations/runtime terms",
}


def route_message(message: str) -> RouteDecision:
    normalized = message.lower()
    matches_by_intent = {
        intent: _matched_keywords(normalized, keywords)
        for intent, keywords in KEYWORDS.items()
    }
    intent = _best_intent(matches_by_intent)
    matched_keywords = matches_by_intent.get(intent, []) if intent != "chat" else []
    confidence = _confidence(len(matched_keywords))

    return RouteDecision(
        intent=intent,
        confidence=confidence,
        use_memory_recommended=intent == "memory",
        reason=REASONS[intent],
        signals={
            "matched_keywords": matched_keywords,
            "message_length": len(message),
        },
    )


def _matched_keywords(message: str, keywords: list[str]) -> list[str]:
    return [keyword for keyword in keywords if keyword in message]


def _best_intent(matches_by_intent: dict[str, list[str]]) -> str:
    priority = ["memory", "code", "ops", "review"]
    best_intent = "chat"
    best_score = 0

    for intent in priority:
        score = len(matches_by_intent[intent])
        if score > best_score:
            best_intent = intent
            best_score = score

    return best_intent if best_score > 0 else "chat"


def _confidence(match_count: int) -> float:
    if match_count <= 0:
        return 0.35
    return min(0.95, 0.58 + (match_count * 0.12))
