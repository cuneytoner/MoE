import hashlib
import numpy as np


class Embedder:
    """
    Lightweight deterministic embedding (no external model yet)
    Later: swap with sentence-transformers or Qwen embeddings
    """

    def embed(self, text: str) -> np.ndarray:
        h = hashlib.sha256(text.encode()).hexdigest()

        # convert hash → pseudo vector
        vec = [int(h[i:i+2], 16) for i in range(0, 32, 2)]

        arr = np.array(vec, dtype=np.float32)

        # normalize
        return arr / (np.linalg.norm(arr) + 1e-8)