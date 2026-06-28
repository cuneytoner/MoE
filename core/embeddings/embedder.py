import hashlib

class Embedder:
    def __init__(self):
        self.dim = 32

    def embed(self, text: str):
        return self._fake_embed(text)

    def _fake_embed(self, text: str):
        base = hashlib.md5(text.encode()).hexdigest()

        vec = []
        for i in range(self.dim):
            h = hashlib.md5((base + str(i)).encode()).hexdigest()
            vec.append(int(h[:8], 16) % 1000 / 1000)

        return vec