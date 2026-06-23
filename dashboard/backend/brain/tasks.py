"""
Task System - Unified task submission and routing interface

Provides submit_task() which:
1. Routes task using MOE router
2. Wraps task with metadata
3. Pushes to Redis queue
4. Returns queued object
"""

import uuid
import json
from datetime import datetime
from typing import Dict

from brain.queue import push_task
from brain.router import route_task


def submit_task(task_payload: Dict) -> Dict:
    """
    Submit a task for distributed execution.
    
    The task goes through:
    1. Routing (determines target node)
    2. Wrapping (adds metadata)
    3. Queueing (pushed to Redis)
    
    Args:
        task_payload: Task data dictionary
    
    Returns:
        Queued task object with ID, target, and metadata
    """
    # Generate unique task ID
    task_id = str(uuid.uuid4())
    
    # Route task to appropriate node
    target_node = route_task(task_payload)
    
    # Create wrapped task object
    queued_task = {
        "id": task_id,
        "target": target_node,
        "timestamp": datetime.utcnow().isoformat(),
        "payload": task_payload,
        "status": "queued"
    }
    
    # Push to main task queue
    try:
        queue_message = push_task("moe_tasks", queued_task)
        queued_task["queue_message"] = queue_message
        
        print(f"[TASK SUBMIT] ID: {task_id}")
        print(f"  Target: {target_node}")
        print(f"  Type: {task_payload.get('type', 'unknown')}")
        print(f"  {queue_message}")
        
        return queued_task
    
    except Exception as e:
        print(f"[ERROR] Failed to submit task {task_id}: {e}")
        raise


def get_task_status(task_id: str) -> Dict:
    """
    Get status of a submitted task (stub).
    
    Full implementation would query Redis or persistent store.
    """
    return {
        "task_id": task_id,
        "status": "unknown",
        "note": "Task status tracking not yet implemented"
    }
