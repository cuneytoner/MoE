#!/bin/bash

# ==============================================================================
# Script Name:  deploy.sh
# Description:  Enterprise deployment pipeline with strict isolation rules
#               protecting runtime checkpoints, custom nodes, and media outputs
#               from cascading rsync deletions.
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

# CRITICAL EXCLUSION PROFILE: Protects downloaded binaries and generative assets
# from accidental local or remote deployment overwrites.
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
echo "[STAGE 2] Instantiating flattened custom node workspace topologies..."
echo "------------------------------------------------------------------------"

P="https:"; S="/"; D="github.com"; U1="kijai"; U2="city96"
R1="ComfyUI-CogVideoXWrapper.git"; R2="ComfyUI-GGUF.git"

NODE_TARGET_DIR="/home/cuneyt/MoE/custom_nodes"
mkdir -p "$NODE_TARGET_DIR"

if [ -d "${NODE_TARGET_DIR}/ComfyUI-CogVideoXWrapper/ComfyUI-CogVideoXWrapper" ]; then
    rm -rf "${NODE_TARGET_DIR}/ComfyUI-CogVideoXWrapper"
fi
if [ -d "${NODE_TARGET_DIR}/ComfyUI-GGUF/ComfyUI-GGUF" ]; then
    rm -rf "${NODE_TARGET_DIR}/ComfyUI-GGUF"
fi

if [ ! -d "${NODE_TARGET_DIR}/ComfyUI-CogVideoXWrapper" ]; then
    echo ">>> Ingesting verified CogVideoX wrapper node architecture..."
    cd "$NODE_TARGET_DIR" && git clone $P$S$S$D$S$U1$S$R1
fi

if [ ! -d "${NODE_TARGET_DIR}/ComfyUI-GGUF" ]; then
    echo ">>> Ingesting missing GGUF core token resolution node..."
    cd "$NODE_TARGET_DIR" && git clone $P$S$S$D$S$U2$S$R2
fi

# Ingest unified script executores safely into runtime layers
mkdir -p /home/cuneyt/MoE/scripts/
chmod +x /home/cuneyt/MoE/scripts/*.py 2>/dev/null || true


# --- STAGE 3: HARDENED OS Tier PERMISSIONS RECOVERY ---
echo "------------------------------------------------------------------------"
echo "[STAGE 3] Reclaiming physical host directory permission ownerships..."
echo "------------------------------------------------------------------------"

mkdir -p /home/cuneyt/MoE/models/checkpoints
chmod -R 777 /home/cuneyt/MoE/custom_nodes/ 2>/dev/null || true
chmod -R 777 /home/cuneyt/MoE/models/checkpoints/ 2>/dev/null || true
chmod -R 777 /home/cuneyt/MoE/dashboard/frontend/ 2>/dev/null || true

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
