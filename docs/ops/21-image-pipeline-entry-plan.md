# 21 Image Pipeline Entry Plan

This page prepares M31.0. It is planning only and does not include a real generation command.

## What M31.0 Should Implement Or Document Next

- A first real image generation runbook.
- Exact ComfyUI / Flux startup checklist.
- Required model files and expected locations.
- How to confirm enough PC-1 VRAM is available.
- How to keep generated outputs under runtime media storage.
- How to return safely to coding mode.

## Which Docs To Read First

1. [18 Image Mode Entry Checklist](18-image-mode-entry-checklist.md)
2. [19 Media Readiness Map](19-media-readiness-map.md)
3. [20 Image Mode Safety Rules](20-image-mode-safety-rules.md)
4. [guided-image-generation.md](../guided-image-generation.md)
5. [image-generation.md](../image-generation.md)
6. [media-lab.md](../media-lab.md)

## Which Checks Must Pass Before First Real Generation

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
make check-media-layout
make check-image-models
make check-comfyui-layout
make comfyui-vram-status
make image-readiness
```

Expected good sign: the operator can see GPU state, llama-server state, Docker state, media layout status, image model status, ComfyUI layout status, VRAM status, and guided readiness status.

## Which Model Files Are Likely Needed

- Flux model components.
- CLIP components.
- VAE components.
- `.safetensors` checkpoints or LoRA files if used.
- GGUF coding models for returning to coding mode.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find ~/MoE_Models_Backup -maxdepth 3 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
```

Expected good sign: required model candidates are present before the first real generation runbook is attempted.

## Which Services Are Likely Involved

- PC-1 GPU and VRAM.
- PC-1 llama-server, if returning to coding mode.
- PC-1 ComfyUI runtime, once a later runbook explicitly starts it.
- Gateway media planning endpoints, if used in advisory/dry-run mode.
- Runtime media storage under `~/MoE/runtime`, not the source repo.

## Which Scripts Already Exist

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find scripts -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
```

Expected good sign: existing readiness and media helper scripts are visible for review.

## Open Questions Before Real Generation

- Which exact Flux/ComfyUI model set is approved for the first run?
- Is llama-server stopped manually before generation, or is there enough VRAM with it running?
- Where should generated outputs appear under `~/MoE/runtime`?
- Which command is a plan/dry-run and which command performs real generation?
- What is the rollback path back to coding mode?
- Which checks prove Continue/Gateway-Auto still works afterward?

Do not run real image generation until these questions are answered in M31.0.
