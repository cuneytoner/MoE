from pathlib import Path


class BgeM3Embedder:
    backend = "bge-m3"

    def __init__(self, model_path: str) -> None:
        self._model_path = model_path

    @property
    def model_path_configured(self) -> bool:
        return bool(self._model_path)

    @property
    def model_path_exists(self) -> bool:
        return Path(self._model_path).exists() if self._model_path else False

    def embed(self, _: str) -> list[float]:
        raise NotImplementedError(
            "bge-m3 backend is prepared but real model loading is not implemented yet"
        )
