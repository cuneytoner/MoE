"""
Worker Pool - Simple worker loop for task execution simulation

Reads from Redis queue and simulates execution.
In production, this would spawn actual execution on target nodes.
"""

import time
from brain.queue import pop_task, queue_length


def worker_loop(poll_interval: int = 1, verbose: bool = True) -> None:
    """
    Main worker loop - continuously polls Redis queue and simulates execution.
    
    Args:
        poll_interval: Seconds to wait between queue polls when empty
        verbose: Print execution logs
    """
    if verbose:
        print("[WORKER] Starting MoE worker loop...")
        print(f"[WORKER] Queue polling interval: {poll_interval}s")
    
    try:
        while True:
            # Check queue length
            qlen = queue_length("moe_tasks")
            
            if qlen > 0:
                # Pop task from queue
                task = pop_task("moe_tasks", timeout=1)
                
                if task:
                    # Simulate execution
                    execute_task(task, verbose=verbose)
                else:
                    # Queue was empty when we checked, wait
                    if verbose:
                        print(f"[WORKER] Queue empty, waiting {poll_interval}s...")
                    time.sleep(poll_interval)
            else:
                # No tasks available
                if verbose:
                    print(f"[WORKER] No tasks in queue, waiting {poll_interval}s...")
                time.sleep(poll_interval)
    
    except KeyboardInterrupt:
        if verbose:
            print("\n[WORKER] Shutting down...")
    except Exception as e:
        print(f"[WORKER ERROR] Unhandled exception: {e}")
        raise


def execute_task(task: dict, verbose: bool = True) -> None:
    """
    Simulate task execution.
    
    Args:
        task: Task object from queue
        verbose: Print execution details
    """
    task_id = task.get("id", "unknown")
    target = task.get("target", "unknown")
    payload = task.get("payload", {})
    task_type = payload.get("type", "unknown")
    
    if verbose:
        print()
        print(f"[EXEC] Task ID: {task_id}")
        print(f"[EXEC] Target: {target}")
        print(f"[EXEC] Type: {task_type}")
        print(f"[EXEC] Payload: {payload}")
        print(f"[EXEC] Status: SIMULATED EXECUTION")
        print()


def start_worker_async() -> None:
    """
    Start worker in async mode (for integration with FastAPI).
    Currently a placeholder - would use threading/async in production.
    """
    print("[WORKER] Async worker start not yet implemented")
    print("[WORKER] Use: python -m brain.worker_pool to run standalone worker")


if __name__ == "__main__":
    # Standalone worker execution
    print("=" * 60)
    print("MoE Worker Pool - Standalone Execution")
    print("=" * 60)
    worker_loop(poll_interval=2, verbose=True)
