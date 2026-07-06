# 22 Image Processing Pipeline Runbook

This is the first beginner-friendly image processing pipeline runbook. It connects operations docs to future real image/media work.

## What This Runbook Is For

- Explain the image pipeline at a beginner level.
- Show what must be checked on PC-1 before image mode.
- Explain where PC-2 fits.
- Keep real generation for M31.1 or later.

## What This Runbook Does NOT Do

- It does not run image generation.
- It does not start ComfyUI.
- It does not stop llama-server.
- It does not switch models.
- It does not add services or change Docker Compose.
- It does not write generated media.

## Pipeline Overview

1. Confirm PC-1 GPU and VRAM state.
2. Confirm whether llama-server is running on port `8000`.
3. Confirm Gateway is available on port `8100`.
4. Confirm image/media model files are present under `~/MoE_Models_Backup/`.
5. Review existing image/media scripts and docs.
6. Run readiness and dry-run planning only.
7. Leave first real generation to M31.1 or later.

## PC-1 Role

PC-1 is the GPU/media host at `192.168.50.1`. It owns:

- GPU and VRAM.
- llama-server on port `8000`.
- Gateway on port `8100`.
- local model backup path `~/MoE_Models_Backup/`.
- media readiness and image scripts.

## PC-2 Role

PC-2 is the support host at `192.168.50.2`. It may provide Memory API, Embed Worker, Postgres, and Qdrant if the media workflow needs memory, embeddings, or storage.

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-2 support services respond if they are needed for the media workflow.

## Required Folders

- Source repo: `~/DiskD/Projects/MoE/codebase`
- Model backup path: `~/MoE_Models_Backup/`
- Runtime output root: `~/MoE/runtime/`

Generated images, model files, and checkpoints must not be committed to Git.

## Required Model Files

Image work may require:

- Flux model files.
- CLIP files.
- VAE files.
- `.safetensors` checkpoints or LoRA files.
- GGUF files for returning to coding mode.

See [23-image-model-inventory-guide.md](23-image-model-inventory-guide.md).

## Required Services

- PC-1 Gateway on port `8100` for Gateway/API checks.
- PC-1 llama-server on port `8000` when returning to coding mode.
- PC-1 GPU runtime for future ComfyUI/Flux work.
- PC-2 support services only if the media workflow needs memory/database services.

## VRAM Safety

llama-server can use PC-1 GPU VRAM. Image generation can also use PC-1 GPU VRAM. Do not assume both fit at the same time.

Stopping llama-server must be a manual operator action. Gateway must not auto-stop it.

## Before Image Mode, Complete M31.2 VRAM Safety Docs

Read these before entering image mode:

- [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md)
- [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md)
- [30-image-mode-return-to-coding.md](30-image-mode-return-to-coding.md)

These docs explain how to inspect VRAM, decide whether llama-server should remain running, stop it manually only if needed, and return to coding mode afterward.

## Before Image Mode

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
docker ps
pgrep -af 'llama-server.*--port 8000' || true
```

Expected good signs:

- `nvidia-smi` shows GPU status and VRAM use.
- `docker ps` shows current containers.
- `pgrep` tells you whether llama-server is running on port `8000`.

## Image Mode Readiness Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find ~/MoE_Models_Backup -maxdepth 3 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
find scripts -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
find docs -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
```

Expected good signs:

- Model candidates are listed if available.
- Existing image/media scripts are visible.
- Existing image/media docs are visible.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-media-layout
make check-image-models
make check-comfyui-layout
make comfyui-vram-status
make image-readiness
```

Expected good sign: readiness checks print status without real image generation.

## Dry-Run Planning Path

Dry-run planning means inspection and readiness only. It should not create real images.

Read next:

- [24-image-first-dry-run-plan.md](24-image-first-dry-run-plan.md)
- [25-comfyui-flux-startup-checklist.md](25-comfyui-flux-startup-checklist.md)
- [26-comfyui-flux-blockers.md](26-comfyui-flux-blockers.md)
- [27-comfyui-flux-startup-evidence-template.md](27-comfyui-flux-startup-evidence-template.md)
- [20-image-mode-safety-rules.md](20-image-mode-safety-rules.md)
- [19-media-readiness-map.md](19-media-readiness-map.md)

## First Real Generation Will Be M31.1 Or Later

This milestone does not include the first real generation command. M31.1 or a later guarded milestone must define ComfyUI / Flux startup and real generation steps.

## Troubleshooting Pointers

- If GPU state is unclear, rerun `nvidia-smi` on PC-1.
- If llama-server is using VRAM, decide manually whether to stop it.
- If model files are missing, document the missing files; do not download automatically.
- If scripts are unclear, read [24-image-first-dry-run-plan.md](24-image-first-dry-run-plan.md).
- If you are unsure where a service runs, read [13-service-location-reference.md](13-service-location-reference.md).
