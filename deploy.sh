#!/bin/bash

# ==============================================================================
# Script Name:  deploy.sh
# Description:  Parametric and dynamic multi-node deployment engine reading 
#               cluster topology from local environment configurations (.env).
# Author:       AI Collaborator
# Year:         2026
# ==============================================================================

# Fail immediately if any piped command triggers an error flag
set -e

# Resolve absolute execution path to accurately locate the .env context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
LOCAL_SRC_DIR="$HOME/DiskD/Projects/MoE/"
LOCAL_RUN_DIR="$HOME/MoE/"
REMOTE_RUN_DIR="/home/cuneyt/MoE/"



# Validate existence of environment manifest
if [ ! -f "$ENV_FILE" ]; then
    echo "[CRITICAL ERROR] Configuration manifest (.env) missing at ${ENV_FILE}"
    exit 1
fi

# Ingest and export configurations from .env
set -a
source "$ENV_FILE"
set +a

echo "========================================================================"
echo "[DEPLOYMENT PIPELINE STARTED] Orchestrating multi-node ecosystem sync..."
echo "========================================================================"

# STAGE 1: Local Node Deployment (PC-1)
echo "------------------------------------------------------------------------"
echo "[STAGE 1] Syncing local runtime cluster targets on PC-1..."
echo "------------------------------------------------------------------------"
mkdir -p "$LOCAL_RUN_DIR"
rsync -avz --delete "$LOCAL_SRC_DIR" "$LOCAL_RUN_DIR"
echo "[SUCCESS] Local runtime sync complete."

# STAGE 2: Remote Workers Iterative Deployment (PC-2, PC-3, etc.)
echo "------------------------------------------------------------------------"
echo "[STAGE 2] Traversing remote node topologies..."
echo "------------------------------------------------------------------------"

# Loop through all space-separated IPs defined inside REMOTE_NODES
for NODE_IP in $REMOTE_NODES; do
    echo ">>> Initializing secure sync pipeline for remote target [${DEPLOY_USER}@${NODE_IP}]"
    
    # Assert network node reachability using explicit SSH timeout restrictions
    if ! ssh -o ConnectTimeout="$SSH_TIMEOUT" -o BatchMode=yes "${DEPLOY_USER}@${NODE_IP}" "exit" 2>/dev/null; then
        echo "    [ERROR] Host ${NODE_IP} unreachable or SSH handshake failed. Skipping node."
        continue
    fi
    
    # Establish remote workspace architecture
    ssh -o ConnectTimeout="$SSH_TIMEOUT" "${DEPLOY_USER}@${NODE_IP}" "mkdir -p ${REMOTE_RUN_DIR}"
    
    # Synchronize codebase over secure active network pipe
    rsync -avz --delete -e ssh "$LOCAL_SRC_DIR" "${DEPLOY_USER}@${NODE_IP}:${REMOTE_RUN_DIR}"
    echo "    [SUCCESS] Target node ${NODE_IP} successfully updated."
done

echo "========================================================================"
echo "[SUCCESS] Synchronization cycle terminated. All active nodes are unified."
echo "========================================================================"
