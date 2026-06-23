#!/bin/bash

# ==============================================================================
# Script Name:  deploy.sh
# Description:  Hardened master enterprise deployment pipeline enforcing clean
#               custom nodes flattening, absolute permissions, and multi-node sync.
# ==============================================================================

set -e

DEPLOY_USER="cuneyt"
NODE_IP="192.168.50.2"

LOCAL_SRC_DIR="/home/cuneyt/DiskD/Projects/MoE"
LOCAL_RUN_DIR="/home/cuneyt/MoE"
REMOTE_RUN_DIR="/home/cuneyt/MoE"

echo "========================================================================"
echo "[DEPLOYMENT PIPELINE STARTED] Syncing clean production runtimes..."
echo "========================================================================"

# --- STAGE 1: LOCAL PC-1 RUNTIME INJECTION ---
echo "------------------------------------------------------------------------"
echo "[STAGE 1] Syncing optimized core assets to local PC-1 Runtime..."
echo "------------------------------------------------------------------------"

mkdir -p "$LOCAL_RUN_DIR"

# CRITICAL EXCLUSION PROFILE: Bypasses heavy data to isolate code updates
rsync -avz --delete --perms --chmod=ugo+x \
    --exclude='.git/' \
    --exclude='venv*/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    --exclude='models/' \
    --exclude='custom_nodes/' \
    --exclude='media_outputs/' \
    --exclude='research_outputs/' \
    "${LOCAL_SRC_DIR}/" "$LOCAL_RUN_DIR"

# --- STAGE 2: OTONOM COMFYUI CUSTOM NODES RETRIEVAL MATRIX ---
echo "------------------------------------------------------------------------"
echo "[STAGE 2] Re-compiling crisp ComfyUI plugin tree architecture..."
echo "------------------------------------------------------------------------"

P="https:"; S="/"; D="github.com"; U1="kijai"; U2="city96"
R1="ComfyUI-CogVideoXWrapper.git"; R2="ComfyUI-GGUF.git"

NODE_TARGET_DIR="/home/cuneyt/MoE/custom_nodes"

# HARDENED SANITIZATION: Wipe out any root locks or broken indexing folders before sync
sudo rm -rf "$NODE_TARGET_DIR" || true
mkdir -p "$NODE_TARGET_DIR"

echo ">>> Ingesting fresh CogVideoX wrapper node architecture..."
cd "$NODE_TARGET_DIR" && git clone $P$S$S$D$S$U1$S$R1

echo ">>> Ingesting fresh GGUF core token resolution node..."
cd "$NODE_TARGET_DIR" && git clone $P$S$S$D$S$U2$S$R2

# --- STAGE 3: HARDENED OS Tier PERMISSIONS RECOVERY ---
echo "------------------------------------------------------------------------"
echo "[STAGE 3] Reclaiming physical host directory permission ownerships..."
echo "------------------------------------------------------------------------"

# Smash 403 access barriers across container boundaries permanently via global open chmods
mkdir -p /home/cuneyt/MoE/models/checkpoints
mkdir -p /home/cuneyt/MoE/scripts

sudo chmod -R 777 /home/cuneyt/MoE/custom_nodes/ || true
sudo chmod -R 777 /home/cuneyt/MoE/models/checkpoints/ || true
sudo chmod -R 777 /home/cuneyt/MoE/dashboard/frontend/ || true
chmod +x /home/cuneyt/MoE/scripts/*.py 2>/dev/null || true

# --- STAGE 4: REMOTE WORKER PC-2 SYNCHRONIZATION ---
echo "------------------------------------------------------------------------"
echo "[STAGE 4] Syncing filtered assets to remote worker PC-2..."
echo "------------------------------------------------------------------------"

echo ">>> Deploying secure pipeline to target node [${DEPLOY_USER}@${NODE_IP}]"
ssh -o ConnectTimeout=3 "${DEPLOY_USER}@${NODE_IP}" "mkdir -p ${REMOTE_RUN_DIR}"

rsync -avz --delete --perms --chmod=ugo+x \
    --exclude='.git/' \
    --exclude='docker/' \
    --exclude='venv*/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    --exclude='models/' \
    --exclude='custom_nodes/' \
    --exclude='media_outputs/' \
    --exclude='research_outputs/' \
    -e ssh "${LOCAL_SRC_DIR}/" "${DEPLOY_USER}@${NODE_IP}:${REMOTE_RUN_DIR}"

echo "========================================================================"
echo "[SUCCESS] Codebase deployment cycle terminated. Clean cluster ready."
echo "========================================================================"
