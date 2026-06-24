"""
Inference Engine Base Classes

Abstract interfaces for different model inference implementations.
Allows pluggable model backends (llama.cpp, vLLM, local inference, etc).
"""

from abc import ABC, abstractmethod
from typing import Dict, Optional


class InferenceEngine(ABC):
    """Abstract base class for inference engines."""
    
    @abstractmethod
    def is_available(self) -> bool:
        """Check if the inference engine is available and ready."""
        pass
    
    @abstractmethod
    def generate(self, prompt: str, **kwargs) -> str:
        """
        Generate text from a prompt.
        
        Args:
            prompt: Input prompt
            **kwargs: Engine-specific parameters
        
        Returns:
            Generated text response
        """
        pass
    
    @abstractmethod
    def get_status(self) -> Dict[str, str]:
        """Get engine status and metadata."""
        pass


class ModelAdapter(ABC):
    """Abstract base class for model-specific adapters."""
    
    def __init__(self, engine: InferenceEngine):
        """
        Initialize adapter with inference engine.
        
        Args:
            engine: InferenceEngine instance to use
        """
        self.engine = engine
    
    @abstractmethod
    def prepare_prompt(self, raw_prompt: str) -> str:
        """
        Prepare prompt for this model.
        May include system prompts, formatting, etc.
        
        Args:
            raw_prompt: Raw input prompt
        
        Returns:
            Model-formatted prompt
        """
        pass
    
    @abstractmethod
    def generate(self, prompt: str, **kwargs) -> str:
        """
        Generate response using this model.
        
        Args:
            prompt: Input prompt
            **kwargs: Model-specific parameters
        
        Returns:
            Generated response
        """
        pass
    
    @abstractmethod
    def extract_response(self, raw_response: str) -> str:
        """
        Extract actual response from raw model output.
        May parse specific format, remove cruft, etc.
        
        Args:
            raw_response: Raw response from engine
        
        Returns:
            Cleaned response text
        """
        pass
