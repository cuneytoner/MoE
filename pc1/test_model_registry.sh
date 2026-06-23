#!/bin/bash

# Test suite for PC1 Model Registry and Multi-Model Execution
# Validates model registry initialization, routing logic, and task execution

set -e

PROJECT_ROOT="/home/cuneyt/DiskD/Projects/MoE"
PC1_DIR="$PROJECT_ROOT/pc1"

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                  PC1 Model Registry & Routing Tests                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 1: Model Registry Imports
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 1] Model Registry Imports"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

try:
    from pc1.model_registry import (
        MODELS, 
        resolve_model, 
        get_model_path,
        is_model_available,
        get_model_info,
        list_available_models,
        list_all_models
    )
    print("✓ All imports successful")
except ImportError as e:
    print(f"✗ Import failed: {e}")
    sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 2: Model Registry Structure
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 2] Model Registry Structure"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import MODELS

required_models = ["coder", "video", "vision", "diffusion_text"]
for model_key in required_models:
    if model_key not in MODELS:
        print(f"✗ Missing model: {model_key}")
        sys.exit(1)
    
    model_info = MODELS[model_key]
    required_fields = ["name", "type", "file", "description"]
    for field in required_fields:
        if field not in model_info:
            print(f"✗ Model {model_key} missing field: {field}")
            sys.exit(1)

print(f"✓ Model registry has {len(MODELS)} models with complete metadata")
for key, info in MODELS.items():
    print(f"  - {key:20} ({info['type']:20}) → {info['file']}")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 3: Routing Logic - Code Tasks
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 3] Routing Logic - LLM Tasks"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import resolve_model

# Test LLM routing
test_cases = [
    ("code", "coder"),
    ("chat", "coder"),
    ("reasoning", "coder"),
    ("instruction", "coder"),
]

for task_type, expected_model in test_cases:
    model_key = resolve_model(task_type)
    if model_key == expected_model:
        print(f"✓ {task_type:15} → {model_key}")
    else:
        print(f"✗ {task_type:15} → {model_key} (expected {expected_model})")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 4: Routing Logic - Video/Vision Tasks
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 4] Routing Logic - Video & Vision Tasks"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import resolve_model

# Test specialized model routing
test_cases = [
    ("video", "video"),
    ("video_generation", "video"),
    ("image", "vision"),
    ("vision", "vision"),
    ("image_generation", "vision"),
    ("image_understanding", "vision"),
    ("diffusion", "diffusion_text"),
    ("text_encoding", "diffusion_text"),
]

for task_type, expected_model in test_cases:
    model_key = resolve_model(task_type)
    if model_key == expected_model:
        print(f"✓ {task_type:20} → {model_key}")
    else:
        print(f"✗ {task_type:20} → {model_key} (expected {expected_model})")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 5: Default Routing
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 5] Default Routing (Unknown Types)"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import resolve_model

# Test default routing for unknown types
unknown_types = ["unknown", "random_type", "xyz", ""]
for task_type in unknown_types:
    model_key = resolve_model(task_type)
    if model_key == "coder":
        print(f"✓ '{task_type}' defaults to coder")
    else:
        print(f"✗ '{task_type}' routed to {model_key} (expected coder)")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 6: Model Info Retrieval
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 6] Model Info Retrieval"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import get_model_info, resolve_model

# Test retrieving info for routed models
task_types = ["code", "video", "image"]
for task_type in task_types:
    model_key = resolve_model(task_type)
    model_info = get_model_info(model_key)
    
    if model_info and "name" in model_info:
        print(f"✓ {task_type:10} → {model_key:20} ({model_info['name']})")
    else:
        print(f"✗ Failed to get info for {model_key}")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 7: Worker Integration - run_model function
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 7] Worker Integration - run_model Function"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import run_model

# Test run_model with different model keys
test_models = ["coder", "video", "vision", "diffusion_text"]
test_prompt = "test prompt"

for model_key in test_models:
    result = run_model(model_key, test_prompt)
    
    # Check result format
    if isinstance(result, str) and len(result) > 0:
        print(f"✓ run_model('{model_key}', '{test_prompt[:20]}...') produced output")
    else:
        print(f"✗ run_model('{model_key}') returned invalid result")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 8: Task Execution with Model Routing
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 8] Task Execution with Model Routing"
python3 << 'EOF'
import sys
import json
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import execute_task
from datetime import datetime

# Create test tasks
test_tasks = [
    {
        "id": "test-task-1",
        "target": "pc1_llm",
        "timestamp": datetime.utcnow().isoformat(),
        "payload": {"type": "code", "prompt": "write hello world"},
        "status": "queued"
    },
    {
        "id": "test-task-2",
        "target": "pc1_llm",
        "timestamp": datetime.utcnow().isoformat(),
        "payload": {"type": "video", "prompt": "generate cyberpunk city"},
        "status": "queued"
    },
    {
        "id": "test-task-3",
        "target": "pc1_llm",
        "timestamp": datetime.utcnow().isoformat(),
        "payload": {"type": "image", "prompt": "beautiful sunset"},
        "status": "queued"
    }
]

for task in test_tasks:
    print(f"\nExecuting task: {task['id']}")
    print(f"  Type: {task['payload']['type']}")
    
    result = execute_task(task)
    
    # Validate result structure
    if not isinstance(result, dict):
        print(f"✗ Result is not a dict")
        sys.exit(1)
    
    required_fields = ["task_id", "model", "input", "output", "status", "timestamp"]
    for field in required_fields:
        if field not in result:
            print(f"✗ Result missing field: {field}")
            sys.exit(1)
    
    # Check model field
    if result["model"] not in ["coder", "video", "vision", "diffusion_text", "unknown"]:
        print(f"✗ Invalid model in result: {result['model']}")
        sys.exit(1)
    
    print(f"✓ Task executed successfully")
    print(f"  Model: {result['model']}")
    print(f"  Status: {result['status']}")
    print(f"  Output: {result['output'][:60]}...")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 9: Case Insensitivity in Routing
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 9] Case Insensitivity in Routing"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import resolve_model

# Test various case combinations
test_cases = [
    ("CODE", "coder"),
    ("Code", "coder"),
    ("VIDEO", "video"),
    ("Video", "video"),
    ("IMAGE", "vision"),
    ("Image", "vision"),
]

for task_type, expected in test_cases:
    model_key = resolve_model(task_type)
    if model_key == expected:
        print(f"✓ '{task_type}' → {model_key}")
    else:
        print(f"✗ '{task_type}' → {model_key} (expected {expected})")
        sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 10: Result Format with Model Info
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 10] Result Format Includes Model Info"
python3 << 'EOF'
import sys
import json
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import execute_task
from datetime import datetime

task = {
    "id": "model-test-task",
    "target": "pc1_llm",
    "timestamp": datetime.utcnow().isoformat(),
    "payload": {"type": "code", "prompt": "hello"},
    "status": "queued"
}

result = execute_task(task)

# Verify model field is present and not empty
if "model" not in result:
    print("✗ 'model' field missing from result")
    sys.exit(1)

if not result["model"] or result["model"] == "unknown":
    print("✗ 'model' field is empty or unknown")
    sys.exit(1)

print(f"✓ Result includes model field: {result['model']}")
print(f"✓ Result structure: {json.dumps(result, indent=2)[:150]}...")
EOF
echo

echo
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                         ✓ ALL TESTS PASSED (10/10)                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
