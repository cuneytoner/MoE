"""
PC1 Model Registry - Local Model File Mapping

Maps task types to locally downloaded model files.
No external downloads - purely file-based registry.
"""

from pathlib import Path
from typing import Dict, Optional

# Local model repository path
MODELS_ROOT = Path.home() / "MoE" / "models" / "checkpoints"

# Model registry: Maps model keys to local file paths
MODELS: Dict[str, Dict[str, str]] = {
    # LLM Coder Model - For code, chat, reasoning tasks
    "coder": {
        "name": "Qwen 2.5 Coder 32B",
        "type": "llm",
        "file": "qwen2.5-coder-32b-instruct-q4_k_m.gguf",
        "description": "Coding and chat inference"
    },
    
    # Video Generation Model
    "video": {
        "name": "CogVideoX 5B",
        "type": "video_generator",
        "file": "CogVideoX_5b_12V_GGUF_Q4_0.safetensors",
        "description": "Video generation from text"
    },
    
    # Vision Encoder Model
    "vision": {
        "name": "CLIP L",
        "type": "vision_encoder",
        "file": "clip_l.safetensors",
        "description": "Vision/image understanding"
    },
    
    # Diffusion Text Encoder
    "diffusion_text": {
        "name": "T5 XXL FP8",
        "type": "text_encoder",
        "file": "t5xxl_fp8_e4m3fn.safetensors",
        "description": "Text encoding for diffusion models"
    }
}


def resolve_model(task_type: str) -> str:
    """
    Determine which model to use for a given task type.
    
    Routing rules:
    - code, chat, reasoning → coder
    - video → video
    - image, vision → vision
    - diffusion → diffusion_text
    - default → coder
    
    Args:
        task_type: Task type from the incoming task
    
    Returns:
        Model key to use for execution
    """
    task_type = task_type.lower().strip()
    
    # LLM tasks route to coder model
    if task_type in ["code", "chat", "reasoning", "instruction"]:
        return "coder"
    
    # Video generation tasks
    if task_type in ["video", "video_generation"]:
        return "video"
    
    # Vision/image tasks
    if task_type in ["image", "vision", "image_generation", "image_understanding"]:
        return "vision"
    
    # Diffusion text encoding
    if task_type in ["diffusion", "diffusion_text", "text_encoding"]:
        return "diffusion_text"
    
    # Default: use coder for unknown types
    return "coder"


def get_model_path(model_key: str) -> Optional[Path]:
    """
    Get the full file path for a model.
    
    Args:
        model_key: Model key from MODELS dict
    
    Returns:
        Full path to model file, or None if model not found
    """
    if model_key not in MODELS:
        return None
    
    model_info = MODELS[model_key]
    model_path = MODELS_ROOT / model_info["file"]
    
    return model_path


def is_model_available(model_key: str) -> bool:
    """
    Check if a model file exists locally.
    
    Args:
        model_key: Model key to check
    
    Returns:
        True if model file exists, False otherwise
    """
    model_path = get_model_path(model_key)
    
    if model_path is None:
        return False
    
    return model_path.exists()


def get_model_info(model_key: str) -> Optional[Dict[str, str]]:
    """
    Get metadata about a model.
    
    Args:
        model_key: Model key to look up
    
    Returns:
        Model info dict, or None if not found
    """
    return MODELS.get(model_key)


def list_available_models() -> Dict[str, Dict]:
    """
    Get all locally available models.
    
    Returns:
        Dict of model_key → model_info for available models
    """
    available = {}
    
    for model_key, model_info in MODELS.items():
        if is_model_available(model_key):
            available[model_key] = model_info
    
    return available


def list_all_models() -> Dict[str, Dict]:
    """Get all registered models (available or not)."""
    return MODELS.copy()


if __name__ == "__main__":
    # CLI interface for testing
    print("=" * 70)
    print("PC1 Model Registry")
    print("=" * 70)
    print()
    
    print("All Registered Models:")
    for key, info in MODELS.items():
        path = get_model_path(key)
        exists = "✓" if is_model_available(key) else "✗"
        print(f"  {exists} {key:20} - {info['name']}")
    
    print()
    print("Routing Examples:")
    examples = ["code", "chat", "video", "image", "unknown"]
    for task_type in examples:
        model_key = resolve_model(task_type)
        print(f"  {task_type:15} → {model_key}")
    
    print()
    print("Available Models:")
    available = list_available_models()
    if available:
        for key in available.keys():
            print(f"  ✓ {key}")
    else:
        print("  (No models found in local registry)")
    
    print()
