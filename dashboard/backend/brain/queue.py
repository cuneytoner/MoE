"""
Redis Queue Management Layer

Provides abstraction for pushing/popping tasks from Redis queues.
Handles serialization and error management.
"""

import json
import redis
from typing import Dict, Optional

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


def push_task(queue_name: str, task: Dict) -> str:
    """
    Push a task onto a Redis queue.
    
    Args:
        queue_name: Name of the queue (e.g., "moe_tasks")
        task: Task dictionary to serialize and push
    
    Returns:
        Queue position / confirmation message
    """
    try:
        client = get_redis_client()
        serialized_task = json.dumps(task)
        queue_length = client.rpush(queue_name, serialized_task)
        return f"Task queued at position {queue_length}"
    except Exception as e:
        print(f"[ERROR] Failed to push task to {queue_name}: {e}")
        raise


def pop_task(queue_name: str, timeout: int = 0) -> Optional[Dict]:
    """
    Pop a task from a Redis queue (blocking).
    
    Args:
        queue_name: Name of the queue to read from
        timeout: Block timeout in seconds (0 = no timeout)
    
    Returns:
        Deserialized task dict, or None if timeout/error
    """
    try:
        client = get_redis_client()
        # BLPOP returns (queue_name, task_json) or None on timeout
        result = client.blpop(queue_name, timeout=timeout)
        
        if result:
            queue_name_returned, task_json = result
            task = json.loads(task_json)
            return task
        
        return None
    except Exception as e:
        print(f"[ERROR] Failed to pop task from {queue_name}: {e}")
        return None


def queue_length(queue_name: str) -> int:
    """Get current queue length."""
    try:
        client = get_redis_client()
        return client.llen(queue_name)
    except Exception as e:
        print(f"[ERROR] Failed to get queue length: {e}")
        return 0


def clear_queue(queue_name: str) -> bool:
    """Clear all tasks from a queue."""
    try:
        client = get_redis_client()
        client.delete(queue_name)
        return True
    except Exception as e:
        print(f"[ERROR] Failed to clear queue {queue_name}: {e}")
        return False
