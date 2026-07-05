# 20 Image Mode Safety Rules

Read this before real image generation. These rules are plain-language guardrails for protecting PC-1, GPU VRAM, model files, Docker data, and Git history.

## Rules

1. Do not run image generation until model files are confirmed.
2. Do not assume enough VRAM if llama-server is running.
3. Do not auto-stop llama-server from Gateway.
4. Stop llama-server only manually and deliberately.
5. Do not delete Docker volumes during image troubleshooting.
6. Do not put generated images, model files, or large checkpoints into Git.
7. Keep real generation behind explicit operator action.
8. Gateway media endpoints must remain advisory unless a later milestone explicitly enables real generation.

## First Safety Check

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
```

Expected good signs:

- GPU state is visible.
- The operator knows whether llama-server is running.
- Docker state is visible before any media work.

## Before Stopping llama-server

Ask:

- Am I finished with coding-mode model work?
- Do I need the GPU VRAM for image work?
- Do I know how to return to coding mode?
- Have I read [17-mode-startup-recipes.md](17-mode-startup-recipes.md)?

If the answer is not clearly yes, do not stop it yet.

## Files That Must Stay Out Of Git

- Generated images.
- Generated videos.
- model files.
- checkpoints.
- `.safetensors` files.
- real `.env` files.
- runtime logs and reports unless intentionally reviewed.

## Docker Safety

Do not use:

- `docker volume prune`
- `docker system prune`
- deleting Qdrant/Postgres volumes

These can destroy useful local state.

## Gateway Safety

Gateway must not:

- stop llama-server.
- start ComfyUI.
- switch models automatically.
- execute image generation automatically.
- write media outputs into the source repo.

Future milestones may add guarded workflows, but this page does not.
