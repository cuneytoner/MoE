from core.memory.embedder import Embedder
from core.memory.vector_store import VectorStore


class MemoryManager:

    def __init__(self):
        self.embedder = Embedder()
        self.store = VectorStore()

    # -------------------------
    # STORE EXPERIENCE
    # -------------------------
    def save(self, prompt: str, result: dict):
        vec = self.embedder.embed(prompt)

        self.store.add(vec, {
            "prompt": prompt,
            "result": result
        })

    # -------------------------
    # RETRIEVE SIMILAR
    # -------------------------
    def recall(self, prompt: str):
        vec = self.embedder.embed(prompt)
        return self.store.search(vec)