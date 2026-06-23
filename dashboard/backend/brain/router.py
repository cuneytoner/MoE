"""
MOE Router - Deterministic task routing logic

Routes tasks to appropriate execution nodes based on task type:
- PC1 LLM: code, chat, reasoning tasks
- PC1 GPU: video, image tasks  
- PC2 Worker: research, learning tasks
- Default: PC1 LLM
"""

from typing import Dict


def route_task(task: Dict) -> str:
    """
    Deterministic routing logic for MoE task distribution.
    
    Args:
        task: Task dictionary with at minimum a "type" field
    
    Returns:
        Target node identifier (e.g., "pc1_llm", "pc1_gpu", "pc2_worker")
    """
    task_type = task.get("type", "").lower()
    
    # Route to PC1 LLM node
    if task_type in ["code", "chat", "reasoning"]:
        return "pc1_llm"
    
    # Route to PC1 GPU node
    if task_type in ["video", "image"]:
        return "pc1_gpu"
    
    # Route to PC2 Worker node
    if task_type in ["research", "learning"]:
        return "pc2_worker"
    
    # Default: PC1 LLM
    return "pc1_llm"


def get_routing_info(task_type: str) -> Dict:
    """
    Get routing information for a task type.
    
    Returns detailed routing metadata.
    """
    routes = {
        "code": {
            "target": "pc1_llm",
            "priority": "high",
            "description": "Code generation and analysis"
        },
        "chat": {
            "target": "pc1_llm",
            "priority": "medium",
            "description": "Conversational inference"
        },
        "reasoning": {
            "target": "pc1_llm",
            "priority": "high",
            "description": "Complex reasoning tasks"
        },
        "video": {
            "target": "pc1_gpu",
            "priority": "medium",
            "description": "Video generation and processing"
        },
        "image": {
            "target": "pc1_gpu",
            "priority": "medium",
            "description": "Image generation and processing"
        },
        "research": {
            "target": "pc2_worker",
            "priority": "low",
            "description": "Research and background tasks"
        },
        "learning": {
            "target": "pc2_worker",
            "priority": "low",
            "description": "Model fine-tuning and learning"
        }
    }
    
    return routes.get(
        task_type.lower(),
        {
            "target": "pc1_llm",
            "priority": "medium",
            "description": "Default routing to PC1 LLM"
        }
    )
