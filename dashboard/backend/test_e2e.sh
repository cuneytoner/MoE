#!/bin/bash
# End-to-end integration test
# Starts FastAPI server and worker, then sends test requests

set -e

cd /home/cuneyt/DiskD/Projects/MoE/dashboard/backend

source venv/bin/activate

echo "======================================================"
echo "E2E Integration Test"
echo "Starting: FastAPI Server + Worker + Test Requests"
echo "======================================================"
echo

# Start FastAPI in background
echo "[1] Starting FastAPI server on port 8050..."
uvicorn main:app --host 127.0.0.1 --port 8050 > /tmp/fastapi.log 2>&1 &
FASTAPI_PID=$!
sleep 3

# Start worker in background
echo "[2] Starting MoE worker loop..."
python3 -m brain.worker_pool > /tmp/worker.log 2>&1 &
WORKER_PID=$!
sleep 2

# Send test requests
echo
echo "[3] Sending test requests..."
echo

test_cases=(
    '{"type":"code","prompt":"write a hello world endpoint"}'
    '{"type":"chat","prompt":"what is MoE?"}'
    '{"type":"video","prompt":"generate a 10s video"}'
    '{"type":"image","prompt":"draw a landscape"}'
    '{"type":"research","prompt":"analyze arxiv papers"}'
)

for i in "${!test_cases[@]}"; do
    echo "  Test $((i+1)): ${test_cases[$i]}"
    curl -s -X POST http://127.0.0.1:8050/api/task \
        -H "Content-Type: application/json" \
        -d "${test_cases[$i]}" | python3 -m json.tool | head -10
    echo "  ---"
    sleep 0.5
done

# Wait for worker to process
echo
echo "[4] Waiting for worker to process tasks..."
sleep 3

# Check logs
echo
echo "======================================================"
echo "Worker Execution Log:"
echo "======================================================"
head -50 /tmp/worker.log || echo "(worker log not available)"

echo
echo "======================================================"
echo "Cleaning up..."
kill $FASTAPI_PID 2>/dev/null || true
kill $WORKER_PID 2>/dev/null || true

echo "✓ End-to-end test complete"
echo "======================================================"
