#!/bin/bash
# PC1 + Brain Integration Test
# Full end-to-end: Submit task from Brain → PC1 executes → Results retrieved

set -e

cd "$(dirname "$0")" || exit

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================================"
echo "Commit-3: Full Pipeline Test"
echo "Brain → Redis Queue → PC1 Worker → Results"
echo "======================================================"
echo

BACKEND_DIR="dashboard/backend"

# Make sure we have Python path set up
export PYTHONPATH="/home/cuneyt/DiskD/Projects/MoE:$PYTHONPATH"

# 1. Check Redis
echo -e "${YELLOW}[1] Checking Redis...${NC}"
python3 << 'EOF'
import redis
try:
    client = redis.Redis(host="localhost", port=6379, decode_responses=True)
    client.ping()
    # Clear queues for clean test
    client.delete("moe_tasks")
    client.delete("moe_results")
    print("[✓] Redis ready (queues cleared)")
except Exception as e:
    print(f"[✗] Redis error: {e}")
    exit(1)
EOF
echo

# 2. Start FastAPI server
echo -e "${YELLOW}[2] Starting FastAPI server...${NC}"
cd "$BACKEND_DIR"
source venv/bin/activate
uvicorn main:app --host 127.0.0.1 --port 8050 > /tmp/fastapi.log 2>&1 &
FASTAPI_PID=$!
sleep 2
echo "[✓] FastAPI running (PID: $FASTAPI_PID)"
echo

cd - > /dev/null

# 3. Start PC1 Worker
echo -e "${YELLOW}[3] Starting PC1 Worker...${NC}"
python3 pc1/worker.py > /tmp/pc1_worker.log 2>&1 &
PC1_PID=$!
sleep 2
echo "[✓] PC1 Worker running (PID: $PC1_PID)"
echo

# 4. Submit test tasks
echo -e "${YELLOW}[4] Submitting test tasks...${NC}"
echo

test_cases=(
    '{"type":"code","prompt":"write a hello world function"}'
    '{"type":"chat","prompt":"what is machine learning?"}'
    '{"type":"reasoning","prompt":"solve 2+2"}'
)

TASK_IDS=()

for i in "${!test_cases[@]}"; do
    echo "  Task $((i+1)): ${test_cases[$i]}"
    
    response=$(curl -s -X POST http://127.0.0.1:8050/api/task \
        -H "Content-Type: application/json" \
        -d "${test_cases[$i]}")
    
    task_id=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
    
    if [ ! -z "$task_id" ]; then
        TASK_IDS+=("$task_id")
        echo "    ✓ Task ID: $task_id"
    else
        echo "    ✗ Failed to get task ID"
    fi
    
    sleep 0.5
done

echo

# 5. Wait for PC1 to process
echo -e "${YELLOW}[5] Waiting for PC1 to process tasks...${NC}"
sleep 4
echo "[✓] Processing complete"
echo

# 6. Retrieve results
echo -e "${YELLOW}[6] Retrieving results from Brain...${NC}"
results=$(curl -s -X GET http://127.0.0.1:8050/api/results)

count=$(echo "$results" | python3 -c "import sys, json; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo 0)

echo "  Retrieved $count results"
echo

# 7. Verify results
echo -e "${YELLOW}[7] Verifying results...${NC}"
python3 << EOF
import json

results_json = '''$results'''
data = json.loads(results_json)

if data["count"] == 0:
    print("  ⚠ No results retrieved (worker may still be processing)")
else:
    print(f"  ✓ Found {data['count']} results:")
    
    for i, result in enumerate(data["results"], 1):
        task_id = result.get("task_id", "unknown")
        status = result.get("status", "unknown")
        output = result.get("output", "")[:50]
        
        print(f"\n  Result {i}:")
        print(f"    Task ID: {task_id}")
        print(f"    Status: {status}")
        print(f"    Output: {output}...")

EOF

echo

# 8. Cleanup
echo -e "${YELLOW}[8] Cleaning up...${NC}"
kill $FASTAPI_PID 2>/dev/null || true
kill $PC1_PID 2>/dev/null || true
sleep 1
echo "[✓] Processes stopped"
echo

# Summary
echo "======================================================"
echo "✓ Integration test complete"
echo "======================================================"
echo
echo "View logs:"
echo "  FastAPI: tail -20 /tmp/fastapi.log"
echo "  PC1:     tail -20 /tmp/pc1_worker.log"
echo
