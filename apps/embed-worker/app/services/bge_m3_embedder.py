import os
from pathlib import Path
from typing import ClassVar, Any


class BgeM3Embedder:
    backend = "bge-m3"
    _models: ClassVar[dict[str, Any]] = {}
    _dimensions: ClassVar[dict[str, int]] = {}

    def __init__(self, model_path: str) -> None:
        self._model_path = model_path

    @property
    def model_path_configured(self) -> bool:
        return bool(self._model_path)

    @property
    def model_path_exists(self) -> bool:
        return Path(self._model_path).exists() if self._model_path else False

    @classmethod
    def is_loaded(cls, model_path: str) -> bool:
        return model_path in cls._models

    @classmethod
    def runtime_dimension(cls, model_path: str) -> int | None:
        return cls._dimensions.get(model_path)

    def _load_model(self) -> Any:
        if not self.model_path_configured:
            raise RuntimeError("EMBEDDING_MODEL_PATH is not configured")
        if not self.model_path_exists:
            raise RuntimeError(f"embedding model path does not exist: {self._model_path}")

        if self._model_path not in self._models:
            os.environ.setdefault("HF_HUB_OFFLINE", "1")
            os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")

            try:
                from sentence_transformers import SentenceTransformer
            except ImportError as exc:
                raise RuntimeError(
                    "sentence-transformers is required for EMBEDDING_BACKEND=bge-m3"
                ) from exc

            try:
                self._models[self._model_path] = SentenceTransformer(
                    self._model_path,
                    local_files_only=True,
                )
            except Exception as exc:
                raise RuntimeError(f"failed to load local BGE-M3 model: {exc}") from exc

        return self._models[self._model_path]

    def embed(self, text: str) -> list[float]:
        model = self._load_model()
        try:
            embedding = model.encode(
                text,
                normalize_embeddings=True,
                convert_to_numpy=True,
            )
        except Exception as exc:
            raise RuntimeError(f"failed to generate BGE-M3 embedding: {exc}") from exc

        vector = [float(value) for value in embedding.tolist()]
        self._dimensions[self._model_path] = len(vector)
        return vector
