from core.execution.llm_client import LLMClient

class Router:
    def __init__(self):
        self.client = LLMClient()

    def classify(self, prompt: str) -> str:
        p = prompt.lower()

        if any(x in p for x in ["architecture", "design", "system", "plan"]):
            return "architect"

        if any(x in p for x in ["code", "implement", "function", "class"]):
            return "code"

        if any(x in p for x in ["review", "risk", "analyze"]):
            return "review"

        return "fast"
    
    def select_model(self, intent: str):
        return {
            "architect": "qwen35b",
            "code": "qwen_coder",
            "review": "deepseek",
            "fast": "qwen14b"
        }.get(intent, "qwen14b")

    def route(self, prompt: str):
        intent = self.classify(prompt)
        model = self.select_model(intent)

        response = self.client.chat(
            prompt=prompt,
            model=model
        )

        return {
            "intent": intent,
            "model": model,
            "response": response
        }