# 27 ComfyUI / Flux Startup Evidence Template

Use this template to collect evidence before asking ChatGPT/Codex for the next image-mode step. Do not include secrets or huge logs.

After this startup evidence, use [32-first-image-dry-run-evidence-template.md](32-first-image-dry-run-evidence-template.md) for the full first-image dry-run evidence bundle.

## Collection Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
pwd
git status --short
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
find scripts -maxdepth 4 -type f | grep -Ei 'comfy|flux|image|media' || true
find docs -maxdepth 4 -type f | grep -Ei 'comfy|flux|image|media' || true
find ~/MoE_Models_Backup -maxdepth 4 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
du -sh ~/MoE_Models_Backup/* 2>/dev/null | sort -h
```

Expected good sign: you have enough summarized evidence to decide whether image mode is ready.

## Copy/Paste Template

```text
PC-1 repo status:
- pwd:
- git status --short:

GPU output summary:
- GPU visible yes/no:
- VRAM total:
- VRAM used:
- notable GPU processes:

llama-server running yes/no:
- pgrep result:
- if running, do I still need coding mode? yes/no:

Docker media containers:
- docker ps summary:
- media/comfy containers visible yes/no:

Found image scripts:
- list short paths:

Found image docs:
- list short paths:

Found model files:
- Flux:
- CLIP:
- VAE:
- safetensors:
- GGUF:

Missing model files:
- list missing or uncertain files:

Question / blocker:
- what am I trying to do next?
- what failed or is unclear?
```

## What Not To Paste

- real `.env` contents.
- secrets.
- huge model listings.
- private tokens.
- generated images or model files.
- full Docker logs unless asked.

## Reminder

This template is for readiness evidence only. It does not include a real generation command.
