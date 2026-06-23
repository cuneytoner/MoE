#!/bin/bash
# PC1 Worker - Standalone Test
# Tests the PC1 worker module without FastAPI server

set -e

# Go to project root
cd "$(dirname "$0")/.." || exit
PROJECT_ROOT="$PWD"

cd pc1

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================================"
echo "PC1 Worker - Offline Verification"
echo "======================================================"
echo

# Check if Redis is available
echo -e "${YELLOW}[1] Checking Redis connectivity...${NC}"
python3 << 'EOF'
import sys
try:
    import redis
    client = redis.Redis(host="localhost", port=6379, decode_responses=True)
    client.ping()
    print("[✓] Redis connection successful")
except Exception as e:
    print(f"[✗] Redis not available: {e}")
    print("Make sure Redis is running:")
    print("  docker-compose -f docker/docker-compose.yml up -d redis")
    sys.exit(1)
EOF
echo

# Check PC1 module
echo -e "${YELLOW}[2] Checking PC1 module structure...${NC}"
files=("__init__.py" "worker.py")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✓ $file${NC}"
    else
        echo -e "${YELLOW}  ! $file not found${NC}"
    fi
done
echo

# Test imports
echo -e "${YELLOW}[3] Testing PC1 module imports...${NC}"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

try:
    from pc1.worker import (
        get_redis_client,
        run_llama,
        execute_task,
        push_result
    )
    print("[✓] All PC1 functions imported successfully")
except ImportError as e:
    print(f"[✗] Import failed: {e}")
    exit(1)
EOF
echo

# Test execution engine
echo -e "${YELLOW}[4] Testing execution engine...${NC}"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import run_llama, run_gpu_inference

# Test LLM execution
result = run_llama("hello world")
assert "[LLM OUTPUT]" in result, "LLM output format incorrect"
print(f"[✓] run_llama() works: {result[:60]}...")

# Test GPU execution
result = run_gpu_inference("test image prompt")
assert "[GPU OUTPUT]" in result, "GPU output format incorrect"
print(f"[✓] run_gpu_inference() works: {result[:60]}...")
EOF
echo

# Test task execution
echo -e "${YELLOW}[5] Testing task execution logic...${NC}"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import execute_task

test_task = {
    "id": "test-uuid-123",
    "target": "pc1_llm",
    "timestamp": "2026-06-23T00:00:00",
    "payload": {"type": "code", "prompt": "write a function"},
    "status": "queued"
}

result = execute_task(test_task)

assert result["task_id"] == "test-uuid-123", "Task ID not preserved"
assert "[LLM OUTPUT]" in result["output"], "LLM output not in result"
assert result["status"] == "completed", "Status should be completed"
print("[✓] Task execution logic works")
print(f"  Task ID: {result['task_id']}")
print(f"  Status: {result['status']}")
print(f"  Output: {result['output'][:60]}...")
EOF
echo

# Test result pushing
echo -e "${YELLOW}[6] Testing result queue push...${NC}"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import execute_task, push_result, get_redis_client
import json

# Create test task and execute
test_task = {
    "id": "test-result-push-123",
    "target": "pc1_llm",
    "timestamp": "2026-06-23T00:00:00",
    "payload": {"type": "code", "prompt": "test"},
    "status": "queued"
}

result = execute_task(test_task)

# Clear queue first
client = get_redis_client()
client.delete("moe_results")

# Push result
success = push_result(result)

if success:
    print("[✓] Result pushed successfully")
    
    # Verify in queue
    queue_len = client.llen("moe_results")
    print(f"  Queue length: {queue_len}")
    
    # Verify content
    result_data = client.lpop("moe_results")
    stored_result = json.loads(result_data)
    assert stored_result["task_id"] == "test-result-push-123"
    print("[✓] Result verified in queue")
else:
    print("[✗] Failed to push result")
    exit(1)

# Clean up
client.delete("moe_results")
EOF
echo

echo "======================================================"
echo "✓ All PC1 offline tests passed!"
echo "======================================================"
echo
echo "To run worker with live Redis:"
echo "  python3 pc1/worker.py"
echo
