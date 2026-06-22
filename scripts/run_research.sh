#!/bin/bash

# ==============================================================================
# Script Name:  run_research.sh
# Description:  Autonomous orchestration wrapper designed for PC-2 worker node.
#               Automatically provisions virtual environments and fires crawler.
# ==============================================================================

set -e

# Resolve paths local to PC-2 execution runtime space
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
VENV_PATH="${SCRIPT_DIR}/../venv_research"
OUTPUT_DIR="${SCRIPT_DIR}/../research_outputs"

# Define default fallback research focus if no topic parameter is supplied by cron
TOPIC_QUERY="${1:-Latest developments in Local AI Models and Mixture of Experts architectures 2026}"

echo "========================================================================"
echo "[PC-2 AUTONOMOUS WORKER] Initializing Nightly Research Node Pipeline..."
echo "========================================================================"

# Guarantee persistent storage space for markdown outputs exists
mkdir -p "$OUTPUT_DIR"

# Establish and validate independent virtual environment context
if [ ! -d "$VENV_PATH" ]; then
    echo "[INFO] Python environment missing on PC-2. Building runtime environment..."
    python3 -m venv "$VENV_PATH"
    source "${VENV_PATH}/bin/activate"
    pip install --upgrade pip
    pip install requests beautifulsoup4
else
    echo "[INFO] Ingesting validated Python environment context..."
    source "${VENV_PATH}/bin/activate"
fi

# Pivot directory context directly to the output layer so the python agent saves correctly
cd "$OUTPUT_DIR"

# Fire the master web crawler agent
python3 "${SCRIPT_DIR}/research_worker.py" "$TOPIC_QUERY"

echo "========================================================================"
echo "[SUCCESS] Asynchronous exploration phase concluded. Report compiled."
echo "========================================================================"
