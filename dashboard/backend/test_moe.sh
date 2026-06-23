#!/bin/bash
# MoE Redis + Brain Router Test Guide
# This script provides instructions and helpers for testing the system

set -e

echo "======================================================"
echo "MoE Commit-2 Test Suite"
echo "Redis + Brain Router + Job Queue System"
echo "======================================================"
echo

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
echo -e "${YELLOW}[1] Checking dependencies...${NC}"
cd "$(dirname "$0")" || exit

if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found"
    exit 1
fi

if ! command -v redis-cli &> /dev/null; then
    echo -e "${YELLOW}WARNING: redis-cli not found (Redis may still be available via Docker)${NC}"
fi

echo -e "${GREEN}✓ Python3 available${NC}"
echo

# Check venv
echo -e "${YELLOW}[2] Checking Python environment...${NC}"
if [ ! -d "venv" ]; then
    echo "Creating venv..."
    python3 -m venv venv
fi

source venv/bin/activate || . venv/Scripts/activate
echo -e "${GREEN}✓ venv activated${NC}"
echo

# Install dependencies
echo -e "${YELLOW}[3] Installing/updating dependencies...${NC}"
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo

# Check Redis connectivity
echo -e "${YELLOW}[4] Testing Redis connectivity...${NC}"
python3 << 'EOF'
import sys
try:
    from brain.queue import get_redis_client
    client = get_redis_client()
    client.ping()
    print("[✓] Redis connection successful")
except Exception as e:
    print(f"[✗] Redis connection failed: {e}")
    print("Make sure Redis is running (locally or via Docker)")
    sys.exit(1)
EOF
echo -e "${GREEN}✓ Redis is reachable${NC}"
echo

# Test imports
echo -e "${YELLOW}[5] Testing module imports...${NC}"
python3 << 'EOF'
try:
    from brain.queue import push_task, pop_task
    from brain.router import route_task
    from brain.tasks import submit_task
    from brain.worker_pool import worker_loop
    print("[✓] All brain modules imported successfully")
except ImportError as e:
    print(f"[✗] Import failed: {e}")
    exit(1)
EOF
echo -e "${GREEN}✓ All modules importable${NC}"
echo

# Test routing logic
echo -e "${YELLOW}[6] Testing MoE router logic...${NC}"
python3 << 'EOF'
from brain.router import route_task

test_cases = [
    ({"type": "code"}, "pc1_llm"),
    ({"type": "chat"}, "pc1_llm"),
    ({"type": "reasoning"}, "pc1_llm"),
    ({"type": "video"}, "pc1_gpu"),
    ({"type": "image"}, "pc1_gpu"),
    ({"type": "research"}, "pc2_worker"),
    ({"type": "learning"}, "pc2_worker"),
    ({"type": "unknown"}, "pc1_llm"),
]

all_pass = True
for task, expected in test_cases:
    result = route_task(task)
    status = "✓" if result == expected else "✗"
    print(f"  {status} {task['type']:12} -> {result:12} (expected: {expected})")
    if result != expected:
        all_pass = False

if all_pass:
    print("[✓] All routing tests passed")
else:
    print("[✗] Some routing tests failed")
    exit(1)
EOF
echo -e "${GREEN}✓ Router logic verified${NC}"
echo

# Test task submission
echo -e "${YELLOW}[7] Testing task submission...${NC}"
python3 << 'EOF'
from brain.tasks import submit_task
from brain.queue import queue_length, clear_queue

# Clear queue first
clear_queue("moe_tasks")

test_payload = {
    "type": "code",
    "prompt": "write a fastapi endpoint"
}

result = submit_task(test_payload)

if "id" in result and "target" in result and result["target"] == "pc1_llm":
    print(f"[✓] Task submission successful")
    print(f"    Task ID: {result['id']}")
    print(f"    Target: {result['target']}")
    qlen = queue_length("moe_tasks")
    print(f"    Queue length: {qlen}")
else:
    print("[✗] Task submission failed")
    exit(1)

# Cleanup
clear_queue("moe_tasks")
EOF
echo -e "${GREEN}✓ Task system works${NC}"
echo

# Instructions
echo -e "${YELLOW}[8] Next steps:${NC}"
echo
echo "  OPTION A: Run FastAPI server"
echo "    $ source venv/bin/activate"
echo "    $ uvicorn main:app --host 0.0.0.0 --port 8050 --reload"
echo
echo "  OPTION B: Run standalone worker"
echo "    $ source venv/bin/activate"  
echo "    $ python3 -m brain.worker_pool"
echo
echo "  OPTION C: Test API endpoint"
echo "    $ curl -X POST http://localhost:8050/api/task \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"type\":\"code\",\"prompt\":\"write an endpoint\"}'"
echo
echo "  OPTION D: Test routing"
echo "    $ python3 -c 'from brain.router import route_task; print(route_task({\"type\":\"code\"}))'"
echo

echo -e "${GREEN}======================================================"
echo "All tests passed! System is ready."
echo "======================================================${NC}"
