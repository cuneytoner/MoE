#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from huggingface_hub import hf_hub_download

app = FastAPI(title="MoE Ecosystem Orchestration API")

# Enable cross-origin calls for React frontend connectivity
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
    # Dynamically read token from the master config manifest
    token = None
    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith("HF_TOKEN="):
                token = line.split("=")[1].strip().strip('"').strip("'")
                
    try:
        hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=TARGET_DIR,
            token=token
        )
        print(f"[SUCCESS] Download completed for: {filename}")
    except Exception as e:
        print(f"[ERROR] Asset retrieval failed: {e}")

@app.get("/api/status")
def get_cluster_status():
    # Return available hardware-mapped checkpoints in the persistence zone
    models = os.listdir(TARGET_DIR) if os.path.exists(TARGET_DIR) else []
    return {"status": "healthy", "available_checkpoints": models}

@app.post("/api/download")
def trigger_model_download(payload: ModelDownloadRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(async_download_processor, payload.repo_id, payload.filename)
    return {"message": "Download task queued successfully in background.", "asset": payload.filename}

@app.post("/api/switch")
def switch_active_inference_model(payload: ModelSwitchRequest):
    # Parametric dynamic orchestration: rewrite runtime configurations or adjust parameters
    # In a production context, this modifies environment maps or direct container states
    return {
        "status": "initiated",
        "target_model": payload.model_name,
        "allocated_context": payload.context_size,
        "gpu_layers_pinned": payload.gpu_layers
    }
