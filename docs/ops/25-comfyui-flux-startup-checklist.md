# 25 ComfyUI / Flux Startup Checklist

Use this checklist before starting ComfyUI / Flux work. It is readiness-only and does not run image generation.

Before making any VRAM decision, read:

- [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md)
- [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md)

## What This Checklist Is For

- Confirm PC-1 is ready for image runtime work.
- Confirm GPU and VRAM state.
- Confirm whether llama-server is using VRAM.
- Find ComfyUI, Flux, image, and media scripts/docs.
- Find Flux/CLIP/VAE/model files.
- Decide whether to stay in coding mode or enter image mode.

## What This Checklist Does NOT Do

- It does not start ComfyUI.
- It does not run Flux.
- It does not generate images.
- It does not stop llama-server.
- It does not change Docker Compose.
- It does not download models.

## PC-1 Only: Why Image Runtime Is PC-1 Work

PC-1 is the GPU/media host at `192.168.50.1`. ComfyUI / Flux readiness depends on PC-1 GPU VRAM, PC-1 model files under `~/MoE_Models_Backup/`, and local media scripts. PC-2 may provide support services, but PC-2 is not the primary image runtime host in this runbook.

## Step 1: Confirm Repo

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
pwd
git status --short
```

Expected good signs:

- `pwd` prints `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- `git status --short` is empty or only shows changes you recognize.

## Step 2: Confirm GPU

### Run on PC-1

```bash
nvidia-smi
```

Expected good sign: NVIDIA GPU information appears, including memory usage.

## Step 3: Check llama-server VRAM Usage

### Run on PC-1

```bash
pgrep -af 'llama-server.*--port 8000' || true
```

Expected good sign: you know whether llama-server is running on port `8000`. If it is running, it may be using VRAM.

## Step 4: Find ComfyUI/Media Scripts

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find scripts -maxdepth 4 -type f | grep -Ei 'comfy|flux|image|media' || true
```

Expected good sign: relevant readiness or media helper scripts appear. If none appear, read [26-comfyui-flux-blockers.md](26-comfyui-flux-blockers.md).

## Step 5: Find Flux/CLIP/VAE Model Files

### Run on PC-1

```bash
find ~/MoE_Models_Backup -maxdepth 4 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
du -sh ~/MoE_Models_Backup/* 2>/dev/null | sort -h
```

Expected good signs:

- Model candidates are listed if installed.
- The size summary shows model folders/files under `~/MoE_Models_Backup/`.

## Step 6: Check Docker Media Containers If Present

### Run on PC-1

```bash
docker ps
```

Expected good sign: current containers are visible. Media containers may or may not be running yet; this step only checks state.

## Step 7: Check Existing Image Docs

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find docs -maxdepth 4 -type f | grep -Ei 'comfy|flux|image|media' || true
```

Expected good sign: image/media docs are listed for review before starting anything.

## Step 8: Decide Whether To Remain In Coding Mode Or Enter Image Mode

Remain in coding mode if:

- You still need Continue/Gateway-Auto for coding.
- llama-server is running and VRAM is low.
- Flux/CLIP/VAE model files are missing.
- You have not read [20-image-mode-safety-rules.md](20-image-mode-safety-rules.md).

Consider entering image mode only if:

- GPU state is understood.
- model files are present.
- image/media scripts and docs are understood.
- any llama-server stop is manual and deliberate.

## Step 9: What To Paste Back If Blocked

Use [27-comfyui-flux-startup-evidence-template.md](27-comfyui-flux-startup-evidence-template.md). Paste summaries of:

- repo status.
- GPU output.
- whether llama-server is running.
- Docker containers.
- found scripts/docs.
- found or missing model files.
- the blocker question.
