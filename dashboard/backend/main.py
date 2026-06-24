import os
import json
import redis

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from telemetry import (
    get_local_telemetry,
    get_remote_telemetry
)

from downloads import start_download

from config import TARGET_DIR

from brain.tasks import submit_task

app = FastAPI(title="MoE Ecosystem Orchestration API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ModelDownloadRequest(BaseModel):
    repo_id: str
    filename: str


class ModelSwitchRequest(BaseModel):
    model_name: str
    context_size: int = 131072
    gpu_layers: int = 48


@app.get("/api/status")
def get_cluster_status():

    models = (
        os.listdir(TARGET_DIR)
        if os.path.exists(TARGET_DIR)
        else []
    )

    return {
        "status": "healthy",
        "available_checkpoints": models,
        "download_progress": 0,
        "pc1_telemetry": get_local_telemetry(),
        "pc2_telemetry": get_remote_telemetry()
    }


@app.post("/api/download")
def trigger_model_download(
    payload: ModelDownloadRequest
):
    start_download(
        payload.repo_id.strip(),
        payload.filename.strip()
    )

    return {
        "message": "download started",
        "asset": payload.filename
    }


@app.post("/api/switch")
def switch_active_inference_model(
    payload: ModelSwitchRequest
):
    return {
        "status": "initiated",
        "target_model": payload.model_name,
        "allocated_context": payload.context_size,
        "gpu_layers_pinned": payload.gpu_layers
    }


@app.post("/api/task")
def create_task(payload: dict):
    """
    Submit a task to the MoE queue system.
    
    Task routing happens automatically based on type:
    - "code", "chat", "reasoning" → PC1 LLM
    - "video", "image" → PC1 GPU
    - "research", "learning" → PC2 Worker
    - other → PC1 LLM (default)
    
    Example:
    {
        "type": "code",
        "prompt": "write a fastapi endpoint"
    }
    
    Returns the queued task object with ID, target node, and metadata.
    """
    return submit_task(payload)


@app.get("/api/results")
def get_task_results():
    """
    Retrieve completed task results from the PC1 execution layer.
    
    Drains all results from the Redis "moe_results" queue.
    Each result contains:
    - task_id: Original task ID
    - input: Full task object
    - output: Execution result
    - status: "completed" or "error"
    - timestamp: When task completed
    
    Returns:
        List of result objects from PC1 worker execution
    """
    try:
        client = redis.Redis(
            host="localhost",
            port=6379,
            decode_responses=True
        )
        
        results = []
        
        # Drain all results from queue (non-blocking)
        while True:
            result_data = client.lpop("moe_results")
            if result_data is None:
                break
            
            result = json.loads(result_data)
            results.append(result)
        
        return {
            "count": len(results),
            "results": results
        }
    
    except Exception as e:
        return {
            "error": str(e),
            "count": 0,
            "results": []
        }


@app.get("/api/models")
def get_active_models():
    """
    Get information about currently active inference models and backend.
    
    Returns:
        {
            "active_model": "qwen2.5-coder-32b-instruct-q4_k_m",
            "backend": "llama.cpp",
            "status": "ready",
            "inference_endpoint": "http://localhost:8000/v1"
        }
    """
    try:
        # Try to get real inference status from PC1
        try:
            from pc1.inference import LlamaCppClient
            client = LlamaCppClient()
            status = client.get_status()
            
            return {
                "active_model": "qwen2.5-coder-32b-instruct-q4_k_m",
                "backend": "llama.cpp",
                "status": status.get("status", "unknown"),
                "inference_endpoint": "http://localhost:8000/v1",
                "engine_status": status
            }
        except ImportError:
            # Inference layer not available yet
            return {
                "active_model": "qwen2.5-coder-32b-instruct-q4_k_m",
                "backend": "mock",
                "status": "mock_mode",
                "inference_endpoint": None,
                "message": "Running in mock simulation mode (real inference not available)"
            }
    
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "active_model": None,
            "backend": None
        }
