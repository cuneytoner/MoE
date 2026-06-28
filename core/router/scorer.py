import numpy as np

def cosine(a, b):
    if len(a) != len(b):
        raise ValueError("Embedding dimension mismatch")
    a = np.array(a)
    b = np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-8))


class Scorer:
    def score(self, embedding, intent_vectors):
        scores = {}

        for intent, vec in intent_vectors.items():
            scores[intent] = cosine(embedding, vec)

        return scores