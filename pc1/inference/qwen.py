"""
Qwen Model Adapter

Adapter for Qwen models running on llama.cpp OpenAI-compatible server.
"""

from typing import Optional

from .base import ModelAdapter, InferenceEngine
from .llama_cpp import LlamaCppClient


class QwenAdapter(ModelAdapter):
    """
    Adapter for Qwen models (Qwen2.5 Coder, etc).
    
    Handles Qwen-specific prompt formatting and response extraction.
    """
    
    def __init__(self, engine: Optional[InferenceEngine] = None):
        """
        Initialize Qwen adapter.
        
        Args:
            engine: InferenceEngine to use (defaults to LlamaCppClient)
        """
        if engine is None:
            engine = LlamaCppClient(model_name="qwen2.5-coder")
        
        super().__init__(engine)
    
    def prepare_prompt(self, raw_prompt: str) -> str:
        """
        Prepare prompt for Qwen.
        
        Qwen models work well with direct prompts.
        May add system context if needed.
        
        Args:
            raw_prompt: Raw input prompt
        
        Returns:
            Formatted prompt
        """
        # For Qwen, direct prompt is fine
        # Can add system prompt here if needed
        return raw_prompt
    
    def generate(self, prompt: str, **kwargs) -> str:
        """
        Generate response using Qwen.
        
        Args:
            prompt: Input prompt
            **kwargs: Additional parameters (temperature, max_tokens, etc)
        
        Returns:
            Generated response
        """
        # Prepare prompt
        formatted_prompt = self.prepare_prompt(prompt)
        
        # Generate using underlying engine
        raw_response = self.engine.generate(
            formatted_prompt,
            temperature=kwargs.get("temperature", 0.7),
            max_tokens=kwargs.get("max_tokens", 2048),
            **kwargs
        )
        
        # Extract and return response
        return self.extract_response(raw_response)
    
    def extract_response(self, raw_response: str) -> str:
        """
        Extract response from raw model output.
        
        Qwen responses are usually clean, minimal processing needed.
        
        Args:
            raw_response: Raw response from model
        
        Returns:
            Cleaned response
        """
        # Qwen responses are typically clean
        # Just strip whitespace
        return raw_response.strip()


# Singleton instance for convenience
_qwen_adapter: Optional[QwenAdapter] = None


def get_qwen_adapter() -> QwenAdapter:
    """Get or create global Qwen adapter instance."""
    global _qwen_adapter
    if _qwen_adapter is None:
        _qwen_adapter = QwenAdapter()
    return _qwen_adapter


def generate_qwen(prompt: str, **kwargs) -> str:
    """
    Generate text using Qwen model.
    
    Convenience function for direct Qwen inference.
    
    Args:
        prompt: Input prompt
        **kwargs: Model parameters (temperature, max_tokens, etc)
    
    Returns:
        Generated response
    
    Example:
        response = generate_qwen("write a hello world function in Python")
    """
    adapter = get_qwen_adapter()
    return adapter.generate(prompt, **kwargs)
