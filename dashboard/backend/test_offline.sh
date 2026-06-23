#!/bin/bash
# Offline test - verify code structure without requiring Redis
# Run this to validate implementation before starting Redis

set -e

echo "======================================================"
echo "MoE System - Offline Structure Verification"
echo "======================================================"
echo

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd "$(dirname "$0")" || exit

# Activate venv if it exists
if [ -d "venv" ]; then
    source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
fi

# Test 1: Check file structure
echo -e "${YELLOW}[1] Checking brain module structure...${NC}"
files=(
    "brain/__init__.py"
    "brain/queue.py"
    "brain/router.py"
    "brain/tasks.py"
    "brain/worker_pool.py"
)

all_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✓ $file${NC}"
    else
        echo -e "${RED}  ✗ $file${NC}"
        all_exist=false
    fi
done

if [ "$all_exist" = false ]; then
    echo "ERROR: Missing files"
    exit 1
fi
echo

# Test 2: Check main.py has imports
echo -e "${YELLOW}[2] Checking main.py imports...${NC}"
if grep -q "from brain.tasks import submit_task" main.py; then
    echo -e "${GREEN}  ✓ submit_task imported${NC}"
else
    echo -e "${RED}  ✗ submit_task not imported${NC}"
    exit 1
fi

if grep -q '@app.post("/api/task")' main.py; then
    echo -e "${GREEN}  ✓ /api/task endpoint exists${NC}"
else
    echo -e "${RED}  ✗ /api/task endpoint missing${NC}"
    exit 1
fi
echo

# Test 3: Check requirements.txt
echo -e "${YELLOW}[3] Checking requirements.txt...${NC}"
if grep -q "redis" requirements.txt; then
    echo -e "${GREEN}  ✓ redis package listed${NC}"
else
    echo -e "${RED}  ✗ redis package missing${NC}"
    exit 1
fi
echo

# Test 4: Verify Python syntax
echo -e "${YELLOW}[4] Checking Python syntax...${NC}"
python3 -m py_compile brain/__init__.py && echo -e "${GREEN}  ✓ brain/__init__.py${NC}"
python3 -m py_compile brain/queue.py && echo -e "${GREEN}  ✓ brain/queue.py${NC}"
python3 -m py_compile brain/router.py && echo -e "${GREEN}  ✓ brain/router.py${NC}"
python3 -m py_compile brain/tasks.py && echo -e "${GREEN}  ✓ brain/tasks.py${NC}"
python3 -m py_compile brain/worker_pool.py && echo -e "${GREEN}  ✓ brain/worker_pool.py${NC}"
python3 -m py_compile main.py && echo -e "${GREEN}  ✓ main.py${NC}"
echo

# Test 5: Test imports (non-Redis operations)
echo -e "${YELLOW}[5] Testing imports (excluding Redis)...${NC}"
python3 << 'EOF'
import sys
try:
    from brain.router import route_task, get_routing_info
    from brain.worker_pool import execute_task
    print("[✓] Non-Redis imports successful")
except Exception as e:
    print(f"[✗] Import failed: {e}")
    sys.exit(1)
EOF
echo

# Test 6: Test router logic
echo -e "${YELLOW}[6] Testing router logic...${NC}"
python3 << 'EOF'
from brain.router import route_task

tests = [
    ("code", "pc1_llm"),
    ("chat", "pc1_llm"),
    ("reasoning", "pc1_llm"),
    ("video", "pc1_gpu"),
    ("image", "pc1_gpu"),
    ("research", "pc2_worker"),
    ("learning", "pc2_worker"),
    ("unknown", "pc1_llm"),
]

all_pass = True
for task_type, expected_target in tests:
    result = route_task({"type": task_type})
    if result == expected_target:
        print(f"  ✓ {task_type:12} → {result}")
    else:
        print(f"  ✗ {task_type:12} → {result} (expected {expected_target})")
        all_pass = False

if not all_pass:
    exit(1)
EOF
echo

# Test 7: Show Redis connectivity instructions
echo -e "${YELLOW}[7] Redis Status...${NC}"
if command -v redis-cli &> /dev/null; then
    redis-cli ping 2>/dev/null && \
        echo -e "${GREEN}  ✓ Redis running locally${NC}" || \
        echo -e "${YELLOW}  ⚠ Redis not accessible on localhost:6379${NC}"
else
    echo -e "${YELLOW}  ⚠ redis-cli not in PATH (check Docker/remote Redis)${NC}"
fi
echo

# Summary
echo -e "${GREEN}======================================================"
echo "✓ Code structure verified"
echo "=====================================================${NC}"
echo
echo "Next: Start Redis and run full tests"
echo "  $ docker-compose -f docker/docker-compose.yml up -d redis"
echo "  OR"
echo "  $ redis-server"
echo
echo "Then run: bash test_moe.sh"
