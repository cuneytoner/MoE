#!/bin/bash

# Test suite for PC1 Real Inference Layer
# Validates inference engine architecture, model adapters, and integration

set -e

PROJECT_ROOT="/home/cuneyt/DiskD/Projects/MoE"
PC1_DIR="$PROJECT_ROOT/pc1"

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    PC1 Real Inference Layer Tests                          ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 1: Inference Layer Imports
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 1] Inference Layer Imports"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

try:
    from pc1.inference import (
        InferenceEngine,
        ModelAdapter,
        LlamaCppClient,
        QwenAdapter,
        generate_qwen,
        get_qwen_adapter,
        DeepSeekAdapter
    )
    print("✓ All inference layer imports successful")
except ImportError as e:
    print(f"✗ Import failed: {e}")
    sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 2: Base Classes Structure
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 2] Base Classes Abstract Interface"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.base import InferenceEngine, ModelAdapter

# Verify abstract methods exist
required_engine_methods = ['is_available', 'generate', 'get_status']
required_adapter_methods = ['prepare_prompt', 'generate', 'extract_response']

for method in required_engine_methods:
    if not hasattr(InferenceEngine, method):
        print(f"✗ InferenceEngine missing method: {method}")
        sys.exit(1)

for method in required_adapter_methods:
    if not hasattr(ModelAdapter, method):
        print(f"✗ ModelAdapter missing method: {method}")
        sys.exit(1)

print("✓ Base classes have correct abstract interface")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 3: LlamaCppClient Initialization
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 3] LlamaCppClient Initialization"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.llama_cpp import LlamaCppClient

# Test default initialization
client1 = LlamaCppClient()
if client1.base_url != "http://localhost:8000/v1":
    print(f"✗ Default base_url incorrect: {client1.base_url}")
    sys.exit(1)

# Test custom initialization
client2 = LlamaCppClient(
    base_url="http://192.168.1.1:8000/v1",
    timeout=300,
    model_name="qwen2.5-coder"
)

if client2.base_url != "http://192.168.1.1:8000/v1":
    print(f"✗ Custom base_url not set correctly")
    sys.exit(1)

if client2.timeout != 300:
    print(f"✗ Timeout not set correctly")
    sys.exit(1)

print("✓ LlamaCppClient initializes correctly with custom parameters")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 4: LlamaCppClient Unavailable Handling
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 4] LlamaCppClient Graceful Degradation (Server Not Available)"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.llama_cpp import LlamaCppClient

# Test with non-existent server
client = LlamaCppClient(base_url="http://127.0.0.1:9999/v1")

# Should return False without crashing
is_available = client.is_available()
if is_available:
    print("✗ Client reports available when server not running")
    sys.exit(1)

# get_status should work even when unavailable
status = client.get_status()
if status.get("status") != "unavailable":
    print(f"✗ Status not 'unavailable': {status.get('status')}")
    sys.exit(1)

print("✓ LlamaCppClient gracefully handles unavailable server")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 5: QwenAdapter Initialization
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 5] QwenAdapter Initialization and Configuration"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.qwen import QwenAdapter, get_qwen_adapter
from pc1.inference.llama_cpp import LlamaCppClient

# Test creation with default engine
adapter1 = QwenAdapter()
if adapter1.engine is None:
    print("✗ QwenAdapter created without engine")
    sys.exit(1)

# Test creation with custom engine
custom_engine = LlamaCppClient(model_name="custom-qwen")
adapter2 = QwenAdapter(engine=custom_engine)
if adapter2.engine != custom_engine:
    print("✗ Custom engine not assigned to adapter")
    sys.exit(1)

# Test singleton pattern
adapter3 = get_qwen_adapter()
adapter4 = get_qwen_adapter()
if adapter3 is not adapter4:
    print("✗ get_qwen_adapter() not returning singleton")
    sys.exit(1)

print("✓ QwenAdapter initializes correctly with default and custom engines")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 6: Qwen Prompt Preparation
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 6] Qwen Prompt Preparation"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.qwen import QwenAdapter

adapter = QwenAdapter()

# Test prompt preparation (should be minimal for Qwen)
test_prompt = "write a hello world function"
prepared = adapter.prepare_prompt(test_prompt)

if prepared != test_prompt:
    print(f"✗ Prompt preparation changed input unexpectedly")
    sys.exit(1)

# Test response extraction (should be minimal)
test_response = "def hello():\n    print('hello world')\n"
extracted = adapter.extract_response(test_response)

if extracted != test_response.strip():
    print(f"✗ Response extraction not working correctly")
    sys.exit(1)

print("✓ Qwen adapter prompt and response handling works correctly")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 7: Model Registry with Executors
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 7] Model Registry Executor Integration"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.model_registry import MODEL_EXECUTORS, get_model_executor

# Check that executors dict exists
if "coder" not in MODEL_EXECUTORS:
    print("✗ coder executor not in MODEL_EXECUTORS")
    sys.exit(1)

# Test getting executor for coder (should be Qwen)
try:
    executor = get_model_executor("coder")
    
    # Should get generate_qwen function
    if not callable(executor):
        print("✗ Executor is not callable")
        sys.exit(1)
    
    # Check function name
    if "qwen" not in executor.__name__.lower():
        print(f"✗ Executor doesn't appear to be qwen: {executor.__name__}")
        sys.exit(1)
    
    print("✓ Model registry correctly provides qwen executor for coder")
except Exception as e:
    print(f"✗ Failed to get executor: {e}")
    sys.exit(1)
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 8: Worker Integration with Executors
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 8] Worker Integration with Real Inference"
python3 << 'EOF'
import sys
import json
from datetime import datetime
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import execute_task, run_model

# Create a test task
task = {
    "id": "test-exec-task",
    "target": "pc1_llm",
    "timestamp": datetime.utcnow().isoformat(),
    "payload": {"type": "code", "prompt": "hello"},
    "status": "queued"
}

# Execute task
result = execute_task(task)

# Verify result structure
if "model" not in result:
    print("✗ Result missing model field")
    sys.exit(1)

if result["model"] not in ["coder", "video", "vision", "diffusion_text"]:
    print(f"✗ Invalid model in result: {result['model']}")
    sys.exit(1)

if "output" not in result or not result["output"]:
    print("✗ Result missing or empty output")
    sys.exit(1)

print(f"✓ Worker integration successful (model={result['model']}, output_len={len(result['output'])})")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 9: DeepSeek Adapter Stub
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 9] DeepSeek Adapter Stub (Prepared for Future)"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.inference.deepseek import DeepSeekAdapter

# Verify stub exists
if not hasattr(DeepSeekAdapter, '__init__'):
    print("✗ DeepSeekAdapter not properly defined")
    sys.exit(1)

# Try to instantiate (should fail with NotImplementedError)
try:
    adapter = DeepSeekAdapter()
    print("✗ DeepSeekAdapter should raise NotImplementedError when not implemented")
    sys.exit(1)
except NotImplementedError:
    # Expected behavior
    print("✓ DeepSeekAdapter correctly raises NotImplementedError (ready for future)")
EOF
echo

# ──────────────────────────────────────────────────────────────────────────────
# TEST 10: Mock Fallback Execution
# ──────────────────────────────────────────────────────────────────────────────

echo "[TEST 10] Mock Execution Fallback (When Real Inference Unavailable)"
python3 << 'EOF'
import sys
sys.path.insert(0, '/home/cuneyt/DiskD/Projects/MoE')

from pc1.worker import run_model_mock

# Test mock execution
mock_output = run_model_mock("coder", "Qwen 2.5 Coder 32B", "llm", "hello")

if "MOCK" not in mock_output:
    print(f"✗ Mock output doesn't indicate it's mocked: {mock_output[:50]}")
    sys.exit(1)

if "hello" not in mock_output:
    print(f"✗ Mock output doesn't contain input prompt")
    sys.exit(1)

print(f"✓ Mock execution fallback works correctly")
EOF
echo

echo
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✓ ALL TESTS PASSED (10/10)                             ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
