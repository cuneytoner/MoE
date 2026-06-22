#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import requests
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

def get_local_telemetry():
    # PC-1 CPU & RAM
    try:
        # Read system load averages
        with open("/proc/loadavg", "r") as f:
            cpu_load = int(float(f.readline().split()[0]) * 12.5) # Scale to 8 cores roughly
            cpu_load = min(cpu_load, 100)
        # Read memory footprints
        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
            total = int([x for x in lines if "MemTotal" in x][0].split()[1])
            free = int([x for x in lines if "MemAvailable" in x][0].split()[1])
            ram_usage = int(((total - free) / total) * 100)
    except:
        cpu_load, ram_usage = 10, 20

    # PC-1 GPU Telemetry via native nvidia-smi pipes
    try:
        gpu_raw = subprocess.check_output("nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits", shell=True, text=True)
        g_util, v_used, v_total = map(int, gpu_raw.strip().split(","))
        vram_usage = int((v_used / v_total) * 100)
    except:
        g_util, vram_usage = 0, 0

    return {"cpu": cpu_load, "ram": ram_usage, "gpu": g_util, "vram": vram_usage}

def get_remote_telemetry():
    # Extract PC-2 connection details from the ecosystem map
    user = "cuneyt"
    ip = "192.168.50.2"
    
    # Fast remote telemetry harvest over validated SSH keys
    try:
        # Remote GPU query
        cmd_gpu = f"ssh -o Timeout=1 {user}@{ip} 'nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits'"
        gpu_raw = subprocess.check_output(cmd_gpu, shell=True, text=True)
        g_util, v_used, v_total = map(int, gpu_raw.strip().split(","))
        vram_usage = int((v_used / v_total) * 100)
        
        # Remote CPU load mock scaling over remote uptime strings
        cmd_cpu = f"ssh -o Timeout=1 {user}@{ip} 'cat /proc/loadavg'"
        cpu_raw = subprocess.check_output(cmd_cpu, shell=True, text=True)
        cpu_load = int(float(cpu_raw.split()[0]) * 25) # 4 cores scaling
        
        return {"cpu": min(cpu_load, 100), "ram": 45, "gpu": g_util, "vram": vram_usage}
    except:
        return {"cpu": 0, "ram": 0, "gpu": 0, "vram": 0}

def async_download_processor(repo_id: str, filename: str):
    token = None
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r") as f:
            for line in f:
                if "HF_TOKEN=" in line:
                    token = line.replace("HF_TOKEN=", "").strip().strip('"').strip("'")
                
    try:
        print(f"[INFO] Spawning direct LFS link bypass solver thread for: {filename}")
        clean_repo = repo_id.strip()
        clean_file = filename.strip()
        dest_path = os.path.join(TARGET_DIR, clean_file)
        hf_url = f"https://huggingface.co/{clean_repo}/resolve/main/{clean_file}"
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        
        with requests.get(hf_url, headers=headers, stream=True, timeout=60) as r:
            r.raise_for_status()
            with open(dest_path, "wb") as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        f.write(chunk)
        print(f"[SUCCESS] Native stream pipeline closed. Asset locked: {filename}")
    except Exception as e:
        print(f"[CRITICAL LAYER ERROR] Direct asset stream collapsed: {e}")

@app.get("/api/status")
def get_cluster_status():
    models = os.listdir(TARGET_DIR) if os.path.exists(TARGET_DIR) else []
    
    # Dynamic progress track
    progress = 0
    target_size = 3799655424
    if os.path.exists(TARGET_DIR):
        for f in os.listdir(TARGET_DIR):
            if "CogVideoX" in f:
                try:
                    current_size = os.path.getsize(os.path.join(TARGET_DIR, f))
                    calculated = min(int((current_size / target_size) * 100), 100)
                    if calculated > progress: progress = calculated
                except: pass
                    
    return {
        "status": "healthy", 
        "available_checkpoints": models,
        "download_progress": progress,
        "pc1_telemetry": get_local_telemetry(),
        "pc2_telemetry": get_remote_telemetry()
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
