import numpy as np


class VectorStore:
    """
    Simple in-memory vector DB (FAISS-lite)
    """

    def __init__(self):
        self.vectors = []
        self.payloads = []

    def add(self, vector, payload):
        self.vectors.append(vector)
        self.payloads.append(payload)

    def search(self, query_vector, top_k=3):
        if not self.vectors:
            return []

        scores = []

        for i, v in enumerate(self.vectors):
            sim = np.dot(query_vector, v)
            scores.append((sim, self.payloads[i]))

        scores.sort(key=lambda x: x[0], reverse=True)

        return scores[:top_k]