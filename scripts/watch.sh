#!/bin/bash

# ==============================================================================
# Script Name:  watch.sh
# Description:  Professional tabbed TMUX cluster dashboard designed to prevent
#               both width and height compression crashes on high-scaling displays.
# Navigation:   Use [Ctrl+B] then [n] to switch between PC-1 and PC-2 tabs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    DEPLOY_USER="cuneyt"
    REMOTE_NODES="192.168.50.2"
fi

PRIMARY_REMOTE_NODE=$(echo "$REMOTE_NODES" | awk '{print $1}')
SESSION_NAME="cluster_monitor"

if ! command -v tmux &> /dev/null; then
    echo "[ERROR] tmux is not installed."
    exit 1
fi

# Clean previous locked frames completely
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# ------------------------------------------------------------------------------
# TAB 0: PC-1 PERFORMANCE DASHBOARD (Master Core)
# ------------------------------------------------------------------------------
tmux new-session -d -s "$SESSION_NAME" -n "PC-1_Master"

# Split into 2 clean horizontal columns (50% split guarantees over 110+ width capacity)
tmux send-keys -t "$SESSION_NAME":0.0 "btop" ENTER
tmux split-window -h -t "$SESSION_NAME":0.0
tmux send-keys -t "$SESSION_NAME":0.1 "nvtop" ENTER

# ------------------------------------------------------------------------------
# TAB 1: PC-2 PERFORMANCE DASHBOARD (Worker Node)
# ------------------------------------------------------------------------------
tmux new-window -t "$SESSION_NAME" -n "PC-2_Worker"

# Split worker tab into 2 clean horizontal columns via remote network pipeline
tmux send-keys -t "$SESSION_NAME":1.0 "ssh -t ${DEPLOY_USER}@${PRIMARY_REMOTE_NODE} 'btop'" ENTER
tmux split-window -h -t "$SESSION_NAME":1.0
tmux send-keys -t "$SESSION_NAME":1.1 "ssh -t ${DEPLOY_USER}@${PRIMARY_REMOTE_NODE} 'nvtop'" ENTER

# Attach and boot directly into the Master pane view
tmux select-window -t "$SESSION_NAME":0
tmux attach-session -t "$SESSION_NAME"
