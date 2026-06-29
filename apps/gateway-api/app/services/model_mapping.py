from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml


class ModelMapping:
    def __init__(self, config_path: str) -> None:
        self._config_path = Path(config_path)
        self._config = self._load_config()

    def safe_config(self) -> dict[str, Any]:
        return {
            "default_model_target": self.default_model_target,
            "fallback_model_target": self.fallback_model_target,
            "intent_model_targets": self.intent_model_targets,
            "model_targets": self.model_targets,
        }

    @property
    def default_model_target(self) -> str:
        return str(self._config.get("default_model_target") or "deepseek-coder-lite")

    @property
    def fallback_model_target(self) -> str:
        return str(self._config.get("fallback_model_target") or "deepseek-coder-lite")

    @property
    def intent_model_targets(self) -> dict[str, str]:
        values = self._config.get("intent_model_targets")
        if not isinstance(values, dict):
            return {}
        return {str(key): str(value) for key, value in values.items()}

    @property
    def model_targets(self) -> dict[str, dict[str, Any]]:
        values = self._config.get("model_targets")
        if not isinstance(values, dict):
            return {}
        return {
            str(key): value
            for key, value in values.items()
            if isinstance(value, dict)
        }

    def target_for_intent(self, intent: str) -> dict[str, Any]:
        model_target = self.intent_model_targets.get(intent, self.default_model_target)
        target = self.model_targets.get(model_target)
        if not target:
            fallback = self.fallback_model_target
            return {
                "model_target": fallback,
                "model_target_runtime_id": self._runtime_id(fallback),
                "model_mapping_status": "fallback",
            }

        return {
            "model_target": model_target,
            "model_target_runtime_id": self._runtime_id(model_target),
            "model_mapping_status": "mapped",
        }

    def runtime_id(self, model_target: str) -> str | None:
        return self._runtime_id(model_target)

    def _runtime_id(self, model_target: str) -> str | None:
        target = self.model_targets.get(model_target, {})
        runtime_id = target.get("runtime_model_id")
        return str(runtime_id) if runtime_id else None

    def _load_config(self) -> dict[str, Any]:
        with self._config_path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle) or {}
        if not isinstance(data, dict):
            return {}
        return data


@lru_cache
def get_model_mapping(config_path: str) -> ModelMapping:
    return ModelMapping(config_path)
