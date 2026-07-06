# 28 Image Mode VRAM Safety

This guide explains VRAM safety before entering image mode on PC-1.

## What This Guide Is For

- Help a beginner understand why image mode needs GPU memory.
- Show how to inspect PC-1 GPU and llama-server state.
- Explain when to keep llama-server running and when to consider stopping it manually.
- Keep Gateway separate from llama-server control.

## What This Guide Does NOT Do

- It does not stop llama-server.
- It does not start llama-server.
- It does not start ComfyUI.
- It does not run image generation.
- It does not switch models.
- It does not change Docker Compose.

## Why Image Mode Needs VRAM

Image generation with ComfyUI / Flux can use a large amount of PC-1 GPU VRAM. If another GPU-heavy process is already running, image mode may fail or become unstable.

## Why llama-server May Block Image Generation

llama-server runs on PC-1 port `8000` and can use GPU VRAM for coding models. If it is running while image mode starts, there may not be enough VRAM for ComfyUI / Flux.

## Safe Rule: Inspect First, Stop Manually Only If Needed

Always inspect GPU and process state first. Stop llama-server only if:

- you intentionally want to leave coding mode,
- image mode needs the VRAM,
- you know how to start llama-server again,
- and you are the human operator making that decision.

Gateway must not auto-stop llama-server.

## PC-1 GPU Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
```

Expected good signs:

- `nvidia-smi` shows the NVIDIA RTX 5060 Ti.
- VRAM total and used memory are visible.
- GPU processes are understandable.

## llama-server Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
pgrep -af 'llama-server.*--port 8000' || true
curl -fsS http://127.0.0.1:8000/v1/models | jq . || true
```

Expected good signs:

- The llama-server process is either clearly present or absent.
- If llama-server is running, `/v1/models` returns JSON.
- If it is absent, the command fails safely because of `|| true`.

## Docker Media Container Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
find scripts -maxdepth 4 -type f | grep -Ei 'image|comfy|flux|media|vram' || true
```

Expected good signs:

- Docker container state is visible.
- Relevant image/media/VRAM scripts are visible if present.
- Gateway remains separate from llama-server control.

## Decision Table: Keep llama-server Running Or Stop It

| Situation | Decision |
| --- | --- |
| You are still coding in Continue | Keep llama-server running |
| `nvidia-smi` shows plenty of free VRAM and image work is only readiness checks | Keep llama-server running |
| Real image mode needs more VRAM and coding work is paused | Consider manual stop |
| You do not know how to restart llama-server | Keep it running and read [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md) |
| Gateway or Continue still needs coding model responses | Keep llama-server running |

## What To Paste Back If Unsure

Paste a short summary:

- GPU name and VRAM used/total from `nvidia-smi`.
- Whether `pgrep` found llama-server.
- Whether `/v1/models` responded.
- Docker container summary.
- Which image/media scripts were found.

Do not paste secrets, real `.env` files, or huge logs.
