#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
VENV_PATH="/home/cuneyt/MoE/venv_downloader"

# Enforce active python virtual environment
source "${VENV_PATH}/bin/activate"

# Fire the clean python downloader module
python3 "${SCRIPT_DIR}/download_models.py"
