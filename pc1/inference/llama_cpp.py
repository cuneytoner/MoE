"""
llama.cpp OpenAI-compatible Server Integration

Connects to llama.cpp server exposing OpenAI-compatible chat completion API.
"""

import requests
import json
from typing import Dict, Optional

from .base import InferenceEngine


class LlamaCppClient(InferenceEngine):
    """
    Client for llama.cpp OpenAI-compatible API.
    
    Assumes llama.cpp is running on localhost:8000 with:
    - /v1/chat/completions endpoint
    - OpenAI-compatible request/response format
    """
    
    def __init__(
        self,
        base_url: str = "http://localhost:8000/v1",
        timeout: int = 120,
        model_name: str = "local-model"
    ):
        """
        Initialize llama.cpp client.
        
        Args:
            base_url: Base URL of llama.cpp API server
            timeout: Request timeout in seconds
            model_name: Model name for API requests
        """
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.model_name = model_name
        self._cache_availability = None
    
    def is_available(self) -> bool:
        """Check if llama.cpp server is running and responsive."""
        try:
            if self._cache_availability is not None:
                return self._cache_availability
            
            # Test connectivity to server
            response = requests.get(
                f"{self.base_url}/models",
                timeout=5
            )
            self._cache_availability = response.status_code == 200
            return self._cache_availability
        except Exception as e:
            self._cache_availability = False
            return False
    
    def get_status(self) -> Dict[str, str]:
        """Get server and model status."""
        try:
            if self.is_available():
                return {
                    "status": "ready",
                    "backend": "llama.cpp",
                    "base_url": self.base_url,
                    "model": self.model_name
                }
            else:
                return {
                    "status": "unavailable",
                    "backend": "llama.cpp",
                    "base_url": self.base_url,
                    "error": "Server not responding"
                }
        except Exception as e:
            return {
                "status": "error",
                "backend": "llama.cpp",
                "error": str(e)
            }
    
    def generate(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        top_p: float = 0.9,
        **kwargs
    ) -> str:
        """
        Generate text using OpenAI-compatible API.
        
        Args:
            prompt: Input prompt
            temperature: Sampling temperature (0.0-2.0)
            max_tokens: Maximum tokens to generate
            top_p: Nucleus sampling parameter
            **kwargs: Additional parameters
        
        Returns:
            Generated text response
        
        Raises:
            Exception: If API request fails
        """
        if not self.is_available():
            raise RuntimeError("llama.cpp server is not available")
        
        # Prepare request
        endpoint = f"{self.base_url}/chat/completions"
        
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "top_p": top_p,
            "stream": False
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        try:
            # Send request to llama.cpp
            response = requests.post(
                endpoint,
                json=payload,
                headers=headers,
                timeout=self.timeout
            )
            
            response.raise_for_status()
            
            # Parse response
            result = response.json()
            
            # Extract assistant message
            if "choices" in result and len(result["choices"]) > 0:
                message = result["choices"][0].get("message", {})
                content = message.get("content", "")
                return content
            else:
                raise ValueError("Invalid response format from llama.cpp")
        
        except requests.exceptions.Timeout:
            raise RuntimeError(f"Request timeout after {self.timeout}s")
        except requests.exceptions.ConnectionError as e:
            raise RuntimeError(f"Connection error: {e}")
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Request failed: {e}")
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            raise RuntimeError(f"Failed to parse response: {e}")
