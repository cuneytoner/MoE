#!/bin/bash

# ==============================================================================
# Script Name:  watch.sh
# Description:  Parametric Tmux dashboard parsing .env variables to dynamically
#               monitor hardware behaviors on local and target cluster nodes.
# ==============================================================================

# Locate runtime directory configuration matrix
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Look for .env in the development root since scripts are cloned precisely
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    # Fallback default values if running detached from environment architecture
    DEPLOY_USER="cuneyt"
    REMOTE_NODES="192.168.50.2"
fi

# Extract the primary remote worker node from the array string
PRIMARY_REMOTE_NODE=$(echo "$REMOTE_NODES" | awk '{print $1}')
SESSION_NAME="cluster_monitor"

if ! command -v tmux &> /dev/null; then
    echo "[ERROR] tmux is not installed."
    exit 1
fi

tmux kill-session -t "$SESSION_NAME" 2>/dev/null
tmux new-session -d -s "$SESSION_NAME"

# Build dashboard panes using configured runtime environment hooks
tmux send-keys -t "$SESSION_NAME":0.0 "btop" ENTER

tmux split-window -h -t "$SESSION_NAME":0.0
tmux send-keys -t "$SESSION_NAME":0.1 "ssh -t ${DEPLOY_USER}@${PRIMARY_REMOTE_NODE} 'btop'" ENTER

tmux split-window -v -t "$SESSION_NAME":0.0
tmux send-keys -t "$SESSION_NAME":0.2 "nvtop" ENTER

tmux split-window -v -t "$SESSION_NAME":0.1
tmux send-keys -t "$SESSION_NAME":0.3 "ssh -t ${DEPLOY_USER}@${PRIMARY_REMOTE_NODE} 'nvtop'" ENTER

tmux select-layout -t "$SESSION_NAME" tiled
tmux attach-session -t "$SESSION_NAME"
