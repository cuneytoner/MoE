"""
PC1 Worker - Multi-Model Inference Execution Engine

Consumes tasks from Redis queue and executes them on appropriate local models.
Uses model registry for deterministic model selection based on task type.
Results are pushed back to Redis for Brain to retrieve.

Architecture:
  Brain (PC2) → Redis moe_tasks → PC1 Router → Model Registry → Execution → Redis moe_results
"""

import json
import time
import redis
from datetime import datetime
from typing import Dict, Optional

try:
    from pc1.model_registry import resolve_model, get_model_info, is_model_available, get_model_executor
except ImportError:
    # Support running from pc1 directory directly
    from model_registry import resolve_model, get_model_info, is_model_available, get_model_executor

# Redis connection configuration
REDIS_HOST = "localhost"
REDIS_PORT = 6379
DECODE_RESPONSES = True


def get_redis_client() -> redis.Redis:
    """Get or create Redis client instance."""
    return redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        decode_responses=DECODE_RESPONSES
    )


# ──────────────────────────────────────────────────────────
# REAL INFERENCE EXECUTION ENGINE
# ──────────────────────────────────────────────────────────

def run_model(model_key: str, prompt: str) -> str:
    """
    Execute inference on a specific model.
    
    Uses real inference when available, falls back to mock simulation.
    Delegates to model-specific executors from the registry.
    
    Args:
        model_key: Model key from registry (coder, video, vision, etc.)
        prompt: Input prompt for the model
    
    Returns:
        Generated output from model
    """
    model_info = get_model_info(model_key)
    
    if not model_info:
        return f"[ERROR] Unknown model: {model_key}"
    
    model_name = model_info.get("name", model_key)
    model_type = model_info.get("type", "unknown")
    
    try:
        # Try to get real executor for this model
        executor = get_model_executor(model_key)
        
        print(f"[INFERENCE] Using real {model_name} inference")
        
        # Call real model executor
        output = executor(prompt)
        
        print(f"[INFERENCE] {model_name} completed")
        return output
    
    except NotImplementedError:
        # Fall back to mock simulation if executor not implemented
        print(f"[INFERENCE] Executor for {model_key} not ready, using mock")
        return run_model_mock(model_key, model_name, model_type, prompt)
    
    except Exception as e:
        # Error in executor - return error message
        error_msg = f"[ERROR] Inference failed: {str(e)}"
        print(f"[INFERENCE] {model_name} error: {e}")
        return error_msg


def run_model_mock(model_key: str, model_name: str, model_type: str, prompt: str) -> str:
    """
    Mock execution simulation (fallback when real inference not available).
    
    Args:
        model_key: Model key
        model_name: Human-readable model name
        model_type: Model type (llm, video_generator, etc)
        prompt: Input prompt
    
    Returns:
        Simulated output
    """
    # Simulate execution based on model type
    if model_type == "llm":
        # LLM inference simulation
        time.sleep(0.5)
        return f"[{model_name.upper()} MOCK OUTPUT] {prompt}"
    
    elif model_type == "video_generator":
        # Video generation simulation
        time.sleep(0.8)
        return f"[{model_name.upper()} MOCK OUTPUT] Generated video from: {prompt}"
    
    elif model_type == "vision_encoder":
        # Vision encoding simulation
        time.sleep(0.3)
        return f"[{model_name.upper()} MOCK OUTPUT] Encoded visual features from: {prompt}"
    
    elif model_type == "text_encoder":
        # Text encoding simulation
        time.sleep(0.2)
        return f"[{model_name.upper()} MOCK OUTPUT] Encoded text: {prompt}"
    
    else:
        # Unknown type
        time.sleep(0.3)
        return f"[{model_name.upper()} MOCK OUTPUT] {prompt}"


# ──────────────────────────────────────────────────────────
# TASK EXECUTION
# ──────────────────────────────────────────────────────────

def execute_task(task: Dict) -> Dict:
    """
    Execute a task based on its type and route to the correct model.
    
    Process:
    1. Extract task type from payload
    2. Resolve to model key using registry
    3. Execute on selected model
    4. Return result with model info
    
    Args:
        task: Task dict from Redis queue with structure:
        {
            "id": "uuid",
            "target": "pc1_llm",
            "timestamp": "ISO timestamp",
            "payload": {"type": "code", "prompt": "..."},
            "status": "queued"
        }
    
    Returns:
        Result dict with model info and output
    """
    task_id = task.get("id", "unknown")
    target = task.get("target", "unknown")
    payload = task.get("payload", {})
    task_type = payload.get("type", "unknown")
    prompt = payload.get("prompt", "")
    
    print(f"[PC1 EXEC] Task ID: {task_id}")
    print(f"[PC1 EXEC] Task Type: {task_type}")
    print(f"[PC1 EXEC] Target: {target}")
    
    # Route task to appropriate model
    try:
        # Resolve model from task type
        model_key = resolve_model(task_type)
        print(f"[ROUTE] {task_type} → {model_key}")
        
        # Check if we're handling a PC1 target
        if target != "pc1_llm" and target != "pc1_gpu":
            output = f"[ERROR] Task target {target} not handled by PC1 worker"
            status = "error"
            model_key = "unknown"
            print(f"[RESULT] ERROR - unsupported target")
        else:
            # Execute on selected model
            print(f"[INFERENCE] {model_key} processing: {prompt[:60]}...")
            output = run_model(model_key, prompt)
            status = "completed"
            print(f"[RESULT] {model_key} completed successfully")
    
    except Exception as e:
        output = f"[ERROR] Execution failed: {str(e)}"
        status = "error"
        model_key = "unknown"
        print(f"[RESULT] ERROR - {str(e)}")
    
    # Wrap result with model information
    result = {
        "task_id": task_id,
        "model": model_key,
        "input": task,
        "output": output,
        "status": status,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    print(f"[PC1 EXEC] Output: {output[:80]}...")
    
    return result


# ──────────────────────────────────────────────────────────
# RESULT MANAGEMENT
# ──────────────────────────────────────────────────────────

def push_result(result: Dict) -> bool:
    """
    Push execution result to Redis result queue.
    
    Args:
        result: Result dict from execute_task()
    
    Returns:
        True if successful, False otherwise
    """
    try:
        client = get_redis_client()
        result_json = json.dumps(result)
        queue_length = client.rpush("moe_results", result_json)
        print(f"[PC1 QUEUE] Result queued at position {queue_length}")
        return True
    except Exception as e:
        print(f"[PC1 ERROR] Failed to push result: {e}")
        return False


# ──────────────────────────────────────────────────────────
# WORKER LOOP
# ──────────────────────────────────────────────────────────

def worker_loop(poll_interval: int = 1, verbose: bool = True) -> None:
    """
    Main worker loop - consumes tasks from Redis and executes them.
    
    Args:
        poll_interval: Seconds to wait between polls when queue empty
        verbose: Print execution logs
    """
    if verbose:
        print("[PC1 WORKER] Starting PC1 execution worker...")
        print(f"[PC1 WORKER] Redis: {REDIS_HOST}:{REDIS_PORT}")
        print(f"[PC1 WORKER] Poll interval: {poll_interval}s")
        print("[PC1 WORKER] Waiting for tasks...")
        print()
    
    try:
        while True:
            # Pop task from moe_tasks queue (blocking)
            client = get_redis_client()
            task_data = client.blpop("moe_tasks", timeout=poll_interval)
            
            if task_data:
                # task_data is (queue_name, json_string)
                queue_name, task_json = task_data
                task = json.loads(task_json)
                
                print()
                print("=" * 70)
                
                # Execute task
                result = execute_task(task)
                
                # Push result
                push_result(result)
                
                print("=" * 70)
                print()
            else:
                if verbose:
                    print(f"[PC1 WORKER] Waiting {poll_interval}s for tasks...")
    
    except KeyboardInterrupt:
        if verbose:
            print("\n[PC1 WORKER] Shutting down...")
    except Exception as e:
        print(f"[PC1 WORKER ERROR] Unhandled exception: {e}")
        raise


if __name__ == "__main__":
    # Standalone execution
    print("=" * 70)
    print("PC1 Execution Worker - Standalone Mode")
    print("=" * 70)
    worker_loop(poll_interval=2, verbose=True)
