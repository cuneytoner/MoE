#!/bin/bash

# ==============================================================================
# Script Name:  deploy.sh
# Description:  Optimized multi-node deployment engine with rigorous exclusion
#               filters to prevent Git assets and docs from leaking to runtimes.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "[CRITICAL ERROR] Configuration manifest (.env) missing at ${ENV_FILE}"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Define global rsync exclusion flags to keep runtimes light and secure
RSYNC_EXCLUDES=(
    --exclude='.git/'
    --exclude='.gitignore'
    --exclude='docs/'
    --exclude='venv*/'
    --exclude='.venv/'
    --exclude='__pycache__/'
    --exclude='*.md'
    --exclude='models/'
    --exclude='media_outputs/'
    --exclude='node_modules/'
)

echo "========================================================================"
echo "[DEPLOYMENT PIPELINE STARTED] Syncing clean production runtimes..."
echo "========================================================================"

# STAGE 1: PC-1 Master Node (Full local copy minus filtered files)
echo "------------------------------------------------------------------------"
echo "[STAGE 1] Syncing optimized assets to local PC-1 Runtime..."
echo "------------------------------------------------------------------------"
mkdir -p "$LOCAL_RUN_DIR"
rsync -avz --delete --perms --chmod=ugo+x "${RSYNC_EXCLUDES[@]}" "${LOCAL_SRC_DIR}/" "$LOCAL_RUN_DIR"


echo "[SUCCESS] PC-1 runtime architecture unified."



# STAGE 2: PC-2 Worker Node (Excludes filtered files AND the entire docker dir)
echo "------------------------------------------------------------------------"
echo "[STAGE 2] Syncing filtered assets to remote worker PC-2..."
echo "------------------------------------------------------------------------"

for NODE_IP in $REMOTE_NODES; do
    echo ">>> Deploying secure pipeline to target node [${DEPLOY_USER}@${NODE_IP}]"
    
    if ! ssh -o ConnectTimeout="$SSH_TIMEOUT" -o BatchMode=yes "${DEPLOY_USER}@${NODE_IP}" "exit" 2>/dev/null; then
        echo "    [ERROR] Host ${NODE_IP} unreachable. Skipping node."
        continue
    fi
    
    ssh -o ConnectTimeout="$SSH_TIMEOUT" "${DEPLOY_USER}@${NODE_IP}" "mkdir -p ${REMOTE_RUN_DIR}"
    
    # PC-2 specific constraint: Add --exclude='docker/' to the global exclusion list
    rsync -avz --delete --perms --chmod=ugo+x "${RSYNC_EXCLUDES[@]}" --exclude='docker/' -e ssh "${LOCAL_SRC_DIR}/" "${DEPLOY_USER}@${NODE_IP}:${REMOTE_RUN_DIR}"
    echo "    [SUCCESS] Worker node ${NODE_IP} synchronized successfully."
done


# AUTOMATED REPRODUCIBILITY HOOK: Automatically reclaim user ownership of container-generated root assets
if [ -d "$HOME/MoE/models/checkpoints" ]; then
    sudo chown -R $USER:$USER "$HOME/MoE/models/checkpoints/" 2>/dev/null || true
fi

echo "========================================================================"
echo "[SUCCESS] Deployment cycle terminated. Clean runtimes established."
echo "========================================================================"

