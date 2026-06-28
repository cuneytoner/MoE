import hashlib


class FakeEmbedder:
    backend = "fake"

    def __init__(self, embedding_dim: int) -> None:
        self._embedding_dim = embedding_dim

    def embed(self, text: str) -> list[float]:
        vector: list[float] = []
        counter = 0

        while len(vector) < self._embedding_dim:
            digest = hashlib.sha256(f"{text}:{counter}".encode("utf-8")).digest()
            for byte in digest:
                vector.append((byte / 127.5) - 1.0)
                if len(vector) == self._embedding_dim:
                    break
            counter += 1

        return vector
