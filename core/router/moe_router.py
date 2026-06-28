from core.embeddings.embedder import Embedder
from core.router.scorer import Scorer
from core.router.intent_space import INTENT_VECTORS
from core.execution.llm_client import LLMClient
from core.memory.memory_manager import MemoryManager


class MoERouter:
    """
    M2.6 — Memory-augmented MoE Router
    """

    def __init__(self):
        self.embedder = Embedder()
        self.scorer = Scorer()
        self.client = LLMClient()

        # 🧠 MEMORY LAYER
        self.memory = MemoryManager()

        # model mapping (static base layer)
        self.model_map = {
            "architect": "qwen35b",
            "code": "qwen_coder",
            "review": "deepseek",
            "fast": "qwen14b",
            "chat": "qwen14b"
        }

    # -------------------------
    # SIMPLE CHAT GUARD
    # -------------------------
    def chat_guard(self, prompt: str) -> bool:
        return len(prompt.split()) <= 3

    # -------------------------
    # SEMANTIC ROUTING
    # -------------------------
    def semantic_route(self, embedding):
        scores = self.scorer.score(embedding, INTENT_VECTORS)

        intent = max(scores, key=scores.get)
        confidence = scores[intent]

        return intent, confidence, scores

    # -------------------------
    # MODEL SELECT
    # -------------------------
    def select_model(self, intent: str):
        return self.model_map.get(intent, "qwen14b")

    # -------------------------
    # MAIN ROUTE
    # -------------------------
    def route(self, prompt: str):

        # ==================================================
        # 🧠 1. MEMORY LOOKUP (VERY IMPORTANT)
        # ==================================================
        memory_hits = self.memory.recall(prompt)

        if memory_hits:
            best_score, best_payload = memory_hits[0]

            # MEMORY HIT THRESHOLD
            if best_score > 0.92:
                return {
                    "mode": "memory_hit",
                    "intent": "memory",
                    "model": best_payload["result"]["model"],
                    "response": best_payload["result"]["response"],
                    "memory_score": float(best_score),
                }

        # ==================================================
        # ⚡ 2. CHAT SHORTCUT
        # ==================================================
        if self.chat_guard(prompt):
            model = "qwen14b"

            response = self.client.chat(prompt, model)

            self.memory.save(prompt, {
                "model": model,
                "response": response
            })

            return {
                "mode": "chat_shortcut",
                "intent": "chat",
                "model": model,
                "response": response
            }

        # ==================================================
        # 🧠 3. EMBEDDING + INTENT SCORING
        # ==================================================
        embedding = self.embedder.embed(prompt)

        intent, confidence, scores = self.semantic_route(embedding)

        model = self.select_model(intent)

        # ==================================================
        # ⚙️ 4. LLM EXECUTION
        # ==================================================
        response = self.client.chat(prompt, model)

        # ==================================================
        # 🧠 5. STORE MEMORY (LEARNING STEP)
        # ==================================================
        self.memory.save(prompt, {
            "intent": intent,
            "model": model,
            "response": response,
            "confidence": confidence
        })

        # ==================================================
        # RETURN FULL TRACE
        # ==================================================
        return {
            "mode": "llm",
            "intent": intent,
            "confidence": confidence,
            "model": model,
            "scores": scores,
            "response": response,
        }