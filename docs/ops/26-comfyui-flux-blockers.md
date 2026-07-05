# 26 ComfyUI / Flux Blockers

Use this when the startup checklist gets stuck. Do not run destructive commands or real generation commands from this page.

## No GPU Visible In `nvidia-smi`

Symptom: `nvidia-smi` fails or shows no GPU.

Likely cause: NVIDIA driver/GPU visibility issue.

Run this check:

### Run on PC-1

```bash
nvidia-smi
```

Safe next step: confirm PC-1 GPU/driver state before image work.

What NOT to do: do not start image generation anyway.

## llama-server Is Running And VRAM Is Low

Symptom: `nvidia-smi` shows high VRAM use and `pgrep` shows llama-server on port `8000`.

Likely cause: coding model runtime is using GPU VRAM.

Run this check:

### Run on PC-1

```bash
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
```

Safe next step: decide manually whether to stay in coding mode or stop llama-server later using documented model runtime commands.

What NOT to do: do not let Gateway auto-stop llama-server; do not kill random processes.

## Flux Model File Not Found

Symptom: no file matching `flux` appears under `~/MoE_Models_Backup/`.

Likely cause: model file missing, stored elsewhere, or named differently.

Run this check:

### Run on PC-1

```bash
find ~/MoE_Models_Backup -maxdepth 4 -type f | grep -Ei 'flux' || true
```

Safe next step: document the missing Flux file and expected location.

What NOT to do: do not download automatically and do not place models in the repo.

## CLIP/VAE File Not Found

Symptom: no file matching `clip` or `vae` appears under `~/MoE_Models_Backup/`.

Likely cause: model components missing, stored elsewhere, or named differently.

Run this check:

### Run on PC-1

```bash
find ~/MoE_Models_Backup -maxdepth 4 -type f | grep -Ei 'clip|vae' || true
```

Safe next step: document missing CLIP/VAE files before real generation.

What NOT to do: do not guess paths or copy model files into Git.

## ComfyUI Folder Or Script Not Found

Symptom: no ComfyUI or image scripts are found.

Likely cause: runtime is not installed, scripts are named differently, or the repo only has readiness tooling.

Run this check:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find scripts -maxdepth 4 -type f | grep -Ei 'comfy|image|media|flux' || true
find docs -maxdepth 4 -type f | grep -Ei 'comfy|image|media|flux' || true
```

Safe next step: read the found docs and identify whether a later milestone must add a startup checklist.

What NOT to do: do not invent a ComfyUI command.

## Docker Media Container Not Running

Symptom: `docker ps` does not show media containers.

Likely cause: media profile/services were not started, or this milestone is readiness-only.

Run this check:

### Run on PC-1

```bash
docker ps
```

Safe next step: review [17-mode-startup-recipes.md](17-mode-startup-recipes.md) and [22-image-processing-pipeline-runbook.md](22-image-processing-pipeline-runbook.md).

What NOT to do: do not start services blindly.

## Port Conflict

Symptom: a media service cannot bind to its port.

Likely cause: another local process or container is already using the port.

Run this check:

### Run on PC-1

```bash
docker ps
```

Safe next step: identify which service owns the port before stopping anything.

What NOT to do: do not kill unknown processes.

## Generated Images Path Unclear

Symptom: you do not know where generated images should go.

Likely cause: real generation runbook is not written yet.

Run this check:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find docs -maxdepth 4 -type f | grep -Ei 'image|media|runtime' || true
```

Safe next step: wait for M31.1 or later runbook to define exact output location under `~/MoE/runtime`.

What NOT to do: do not write generated images into the source repo.

## Still In Coding Mode

Symptom: Continue/Gateway coding work is active and llama-server is running.

Likely cause: you have not intentionally switched to image mode.

Run this check:

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

Safe next step: finish coding mode work first, then read [20-image-mode-safety-rules.md](20-image-mode-safety-rules.md).

What NOT to do: do not start image generation while unsure which mode you are in.
