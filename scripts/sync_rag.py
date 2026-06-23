#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import requests
import json

# Absolute layout path resolution
ENV_FILE = "/home/cuneyt/DiskD/Projects/MoE/.env"

def load_environment():
    env = {}
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r") as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip().strip('"').strip("'")
    return env

def harvest_remote_logs(env):
    user = env.get("DEPLOY_USER", "cuneyt")
    ip = env.get("REMOTE_NODES", "192.168.50.2").split()[0]
    remote_dir = env.get("PC2_RESEARCH_DIR", "/home/cuneyt/MoE/research_outputs")
    
    print(f"[INFO] Connecting to worker node [{user}@{ip}] via secure channel...")
    
    # Securely list remote files over existing validated SSH keys
    try:
        ssh_cmd = f"ssh -o ConnectTimeout=3 {user}@{ip} 'mkdir -p {remote_dir} && ls -1 {remote_dir}/*.txt 2>/dev/null || true'"
        remote_files = subprocess.check_output(ssh_cmd, shell=True, text=True).strip().split("\n")
        return [f for f in remote_files if f]
    except Exception as e:
        print(f"[ERROR] Failed to fetch remote log index from PC-2: {e}")
        return []

def inject_to_open_webui(env, file_path, file_content, title):
    api_url = env.get("OPEN_WEBUI_API_URL", "http://localhost:3000/api/v1")
    api_key = env.get("OPEN_WEBUI_API_KEY")
    
    if not api_key or "placeholder" in api_key:
        print("[WARNING] Open-WebUI API key not initialized in .env. Skipping injection.")
        return False
        
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "collection_name": "pc2_autonomous_research",
        "name": title,
        "title": title,
        "content": file_content,
        "tags": ["pc2", "autonomous_research", "automated_ingest"]
    }
    
    try:
        # Open-WebUI v1 Document ingestion endpoint vector
        response = requests.post(f"{api_url}/documents/", headers=headers, json=payload, timeout=10)
        if response.status_code in:
            print(f"[SUCCESS] Synthesized log successfully synced to Open-WebUI vector store: {title}")
            return True
        else:
            print(f"[ERROR] Ingestion failed with status {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"[CRITICAL ERROR] Open-WebUI connection collapsed: {e}")
        return False

def main():
    env = load_environment()
    remote_files = harvest_remote_logs(env)
    
    if not remote_files:
        print("[INFO] No tresh autonomous research logs located on PC-2 workspace. Pipeline idling.")
        return
        
    user = env.get("DEPLOY_USER", "cuneyt")
    ip = env.get("REMOTE_NODES", "192.168.50.2").split()[0]
    
    for remote_file in remote_files:
        title = os.path.basename(remote_file)
        print(f"[INGEST] Processing file foot-print: {title}")
        
        # Read file content directly over the network pipe without saving to local disk
        try:
            cat_cmd = f"ssh {user}@{ip} 'cat {remote_file}'"
            content = subprocess.check_output(cat_cmd, shell=True, text=True)
            
            if content.strip():
                inject_to_open_webui(env, remote_file, content, title)
        except Exception as e:
            print(f"[ERROR] Failed to read streaming segments for {title}: {e}")

if __name__ == "__main__":
    main()
