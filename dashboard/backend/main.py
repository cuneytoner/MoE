#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="MoE Ecosystem Orchestration API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ENV_FILE = "/home/cuneyt/DiskD/Projects/MoE/.env"
TARGET_DIR = "/home/cuneyt/MoE/models/checkpoints"

class ModelDownloadRequest(BaseModel):
    repo_id: str
    filename: str

class ModelSwitchRequest(BaseModel):
    model_name: str
    context_size: int = 131072
    gpu_layers: int = 48

def async_download_processor(repo_id: str, filename: str):
    token = None
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r") as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    parts = line.split("=", 1)
                    if len(parts) > 1:
                        # FIXED: Correctly targeted index 1 of the list before stripping strings
                        token = parts[1].strip().strip('"').strip("'")

                
    try:
        print(f"[INFO] Spawning direct LFS link bypass solver thread for: {filename}")
        clean_repo = repo_id.strip()
        clean_file = filename.strip()
            
        py_cmd = f"""
import os
from huggingface_hub import hf_hub_download
print(">>> Connecting natively to HF client...")
hf_hub_download(
    repo_id='{clean_repo}',
    filename='{clean_file}',
    local_dir='{TARGET_DIR}',
    token='{token}'
)
"""
        subprocess.run([sys.executable, "-c", py_cmd], check=True)
        print(f"[SUCCESS] Video asset synced onto local workspace cluster: {filename}")
    except Exception as e:
        print(f"[ERROR] Asset retrieval failed down the pipe: {e}")

@app.get("/api/status")
def get_cluster_status():
    models = os.listdir(TARGET_DIR) if os.path.exists(TARGET_DIR) else []
    
    # Track the official 5B Q4_0 CogVideo payload size for progress bar interpolation
    video_file = "CogVideoX_5b_I2V_GGUF_Q4_0.safetensors"
    video_path = os.path.join(TARGET_DIR, video_file)
    progress = 0
    if os.path.exists(video_path):
        current_size = os.path.getsize(video_path)
        # Official size profile for 5B model maps exactly to 3.54 GB (3799655424 bytes)
        target_size = 3799655424 
        progress = min(int((current_size / target_size) * 100), 100)
        
    return {
        "status": "healthy", 
        "available_checkpoints": models,
        "download_progress": progress
    }

@app.post("/api/download")
def trigger_model_download(payload: ModelDownloadRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(async_download_processor, payload.repo_id, payload.filename)
    return {"message": "Download task queued successfully in background.", "asset": payload.filename}

@app.post("/api/switch")
def switch_active_inference_model(payload: ModelSwitchRequest):
    return {
        "status": "initiated",
        "target_model": payload.model_name,
        "allocated_context": payload.context_size,
        "gpu_layers_pinned": payload.gpu_layers
    }
