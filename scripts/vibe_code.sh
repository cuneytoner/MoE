#!/bin/bash

# ==============================================================================
# Script Name:  vibe_code.sh
# Description:  Self-contained autopilot deployment launcher that automatically
#               manages its virtual environment boundaries seamlessly.
# ==============================================================================

set -e

# Establish local directory architecture context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
VENV_PATH="${SCRIPT_DIR}/../venv_aider"

echo "========================================================================"
echo "[VIBE CODING SYSTEM ACTIVE] Initializing Aider Autopilot Cluster..."
echo "========================================================================"

# Automated Virtual Environment Enforcement Matrix
if [ ! -d "$VENV_PATH" ]; then
    echo "[INFO] Isolated environment missing. Building venv at ${VENV_PATH}..."
    python3 -m venv "$VENV_PATH"
    source "${VENV_PATH}/bin/activate"
    pip install --upgrade pip
    pip install aider-chat
else
    echo "[INFO] Activating managed virtual environment context..."
    source "${VENV_PATH}/bin/activate"
fi

# Explicit OpenAI-compatible bridge mapping routing onto local Ollama Core
export OLLAMA_API_BASE="http://128.0.0.1:11434"

# Launch Aider directly bypassing Ollama wrapper layers targeting our raw llama.cpp server
aider \
    --model openai/qwen2.5-coder-32b-instruct-q4_k_m \
    --openai-api-base http://localhost:8000/v1 \
    --openai-api-key "raw-engine-bypass" \
    --auto-commits \
    --dark-mode \
    --chat-language "English"
