# 19 Media Readiness Map

This document maps what must exist before image generation work starts. It is readiness-only.

## What This Document Is For

- Explain PC-1 and PC-2 roles for image/media work.
- List existing image/media scripts and docs.
- Show beginner-safe readiness checks.
- Clarify VRAM ownership before real generation.
- Prepare for M31.0 image processing runbooks.

## What This Document Does NOT Do

- It does not run image generation.
- It does not start ComfyUI.
- It does not stop llama-server.
- It does not switch models.
- It does not add services or change Docker Compose.

## PC-1 Media Role

PC-1 is the media/GPU host at `192.168.50.1`. It owns:

- GPU and VRAM checks.
- llama-server on port `8000`.
- Gateway on port `8100`.
- model backup path `~/MoE_Models_Backup/`.
- image/media readiness scripts in the repo.

Image/media work may need llama-server stopped manually to free VRAM. Gateway must not stop it automatically.

## PC-2 Media Role

PC-2 is the worker/support host at `192.168.50.2`. It may provide:

- Memory API on port `8101`.
- Embed Worker on port `8102`.
- Postgres on port `5432`.
- Qdrant on ports `6333/6334`.

PC-2 is not the primary GPU/media host in the current runbook.

## GPU / VRAM Readiness

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
docker ps
pgrep -af 'llama-server.*--port 8000' || true
```

Expected good signs:

- `nvidia-smi` shows the GPU and current VRAM use.
- `docker ps` shows current containers.
- `pgrep` tells you whether llama-server is running on port `8000`.

## Existing Image/Media Scripts

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find scripts -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
```

Expected good sign: output includes existing image, ComfyUI, Flux, or media helper scripts.

Known Make targets include:

- `make check-media-layout`
- `make check-image-models`
- `make check-comfyui-layout`
- `make check-comfyui-runtime`
- `make comfyui-vram-status`
- `make image-readiness`
- `make image-dry-run`
- `make gateway-media-plan`

## Existing Image/Media Docs

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find docs -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
```

Expected good sign: output includes docs such as `guided-image-generation.md`, `image-generation.md`, and `media-lab.md`.

## Required Model Folders

Expected model root:

- `~/MoE_Models_Backup/`

Media work may need Flux, CLIP, VAE, `.safetensors`, or other image assets. Coding mode uses GGUF model files.

## Model File Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find ~/MoE_Models_Backup -maxdepth 3 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
```

Expected good sign: relevant model candidates are listed if they exist. No output means the operator must review model availability before image work.

## Service Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

Expected good sign: Gateway and llama-server respond if coding mode is active.

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-2 support services respond if media work depends on memory, embeddings, or storage.

## Safe Readiness Flow

1. Confirm the task really needs image/media mode.
2. Check GPU and VRAM on PC-1.
3. Check whether llama-server is running.
4. Confirm model files or candidates exist.
5. Review existing image/media scripts and docs.
6. Run readiness checks only.
7. Decide manually whether llama-server should be stopped for VRAM.
8. Do not run real generation until M31.0 runbooks are ready.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-media-layout
make check-image-models
make check-comfyui-layout
make comfyui-vram-status
make image-readiness
```

Expected good sign: readiness commands print status without running real image generation.

## What Is Still Future Work

- M31.0 image processing pipeline runbook.
- M31.1 ComfyUI / Flux startup checklist.
- Real first-image operator flow.
- Guarded media runtime operations.
- Video/3D/media-specific readiness maps.
