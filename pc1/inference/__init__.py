"""
PC1 Inference Layer

Modular inference engine architecture supporting multiple model backends.
"""

from .base import InferenceEngine, ModelAdapter
from .llama_cpp import LlamaCppClient
from .qwen import QwenAdapter, generate_qwen, get_qwen_adapter
from .deepseek import DeepSeekAdapter

__all__ = [
    "InferenceEngine",
    "ModelAdapter",
    "LlamaCppClient",
    "QwenAdapter",
    "generate_qwen",
    "get_qwen_adapter",
    "DeepSeekAdapter",
]
