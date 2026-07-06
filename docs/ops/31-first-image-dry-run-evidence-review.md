# 31 First Image Dry Run Evidence Review

This guide collects dry-run evidence before first real image generation. It is documentation-only and does not run image generation.

## What This Dry-Run Proves

- PC-1 repo and Git state are understood.
- GPU and VRAM state are visible.
- llama-server state is understood.
- Docker/media container state is visible.
- image/media scripts and docs are discoverable.
- model inventory is known.
- Gateway/media endpoints are visible if present.
- PC-2 support services are checked if needed.

## What This Dry-Run Does NOT Do

- It does not generate images.
- It does not start ComfyUI.
- It does not stop llama-server.
- It does not switch models.
- It does not change Docker Compose.
- It does not write runtime files.

## Before Collecting Evidence

Read:

- [25-comfyui-flux-startup-checklist.md](25-comfyui-flux-startup-checklist.md)
- [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md)
- [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md)

## Evidence A: Repo And Git State

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
pwd
git status --short
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: `pwd` is the repo path, Git changes are understood, and no `@*` pasted-output files appear.

If bad, read [09-git-workflow.md](09-git-workflow.md).

## Evidence B: GPU And VRAM State

### Run on PC-1

```bash
nvidia-smi
```

Expected good sign: PC-1 GPU is visible and VRAM used/free state is understandable.

If bad, read [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md).

## Evidence C: llama-server State

### Run on PC-1

```bash
pgrep -af 'llama-server.*--port 8000' || true
curl -fsS http://127.0.0.1:8000/v1/models | jq . || true
```

Expected good sign: llama-server is either clearly running with model JSON, or clearly absent.

If bad, read [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md).

If M31.4 proceeds, image-mode preparation must use the guarded path from `scripts/image/image-mode-prepare.sh`, not manual `pkill`.

## Evidence D: Docker/Media Container State

### Run on PC-1

```bash
docker ps
docker compose --env-file .env.example -f infra/docker/docker-compose.yml ps || true
```

Expected good sign: Docker state is visible and media containers, if present, are understood.

If bad, read [26-comfyui-flux-blockers.md](26-comfyui-flux-blockers.md).

## Evidence E: Image/Media Scripts

### Run on PC-1

```bash
find scripts -maxdepth 4 -type f | grep -Ei 'image|comfy|flux|media|vram' || true
```

Expected good sign: relevant readiness, media, ComfyUI, Flux, image, or VRAM scripts are listed.

If bad, read [24-image-first-dry-run-plan.md](24-image-first-dry-run-plan.md).

## Evidence F: Image/Media Docs

### Run on PC-1

```bash
find docs -maxdepth 4 -type f | grep -Ei 'image|comfy|flux|media|vram' || true
```

Expected good sign: relevant image/media docs are listed.

If bad, read [22-image-processing-pipeline-runbook.md](22-image-processing-pipeline-runbook.md).

## Evidence G: Model Inventory

### Run on PC-1

```bash
find ~/MoE_Models_Backup -maxdepth 4 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
du -sh ~/MoE_Models_Backup/* 2>/dev/null | sort -h
```

Expected good sign: model candidates are listed if present, and model folder sizes are understandable.

If bad, read [23-image-model-inventory-guide.md](23-image-model-inventory-guide.md).

## Evidence H: Gateway/Media Endpoints If Present

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq . || true
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-recommendation-summary | jq . || true
```

Expected good sign: Gateway health responds if Gateway is running, and runtime profile summary responds if available.

If bad, read [07-troubleshooting.md](07-troubleshooting.md).

## Evidence I: PC-2 Support Services If Needed

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq . || true
curl -fsS http://192.168.50.2:8102/health | jq . || true
curl -fsS http://192.168.50.2:6333/readyz || true
```

Expected good sign: PC-2 responds if support services are needed for the image workflow.

If bad, read [02-fresh-install-pc2.md](02-fresh-install-pc2.md) and [07-troubleshooting.md](07-troubleshooting.md).

## How To Paste Evidence Back Into ChatGPT/Codex

Use [32-first-image-dry-run-evidence-template.md](32-first-image-dry-run-evidence-template.md). Paste summaries, not huge logs. Do not paste secrets or real `.env` files.

## Go / No-Go Checklist For M31.4

Proceed to M31.4 only if:

- repo state is understood.
- no `@*` pasted-output files are present.
- GPU is visible.
- VRAM state is understood.
- llama-server state is understood.
- Docker/media state is visible.
- image scripts and docs are found.
- model inventory is understood.
- missing model files are listed.
- Gateway health is understood.
- PC-2 checks are done if needed.
- no real image generation command has been run.
- operator explicitly approves moving toward M31.4.
