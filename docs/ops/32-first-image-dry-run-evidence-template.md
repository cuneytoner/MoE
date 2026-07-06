# 32 First Image Dry Run Evidence Template

Fill this out after running [31-first-image-dry-run-evidence-review.md](31-first-image-dry-run-evidence-review.md). Do not include real generation commands.

```text
Date/time:

PC-1 repo status:
- pwd:
- git status --short:
- @* files present yes/no:

GPU summary:
- GPU visible yes/no:
- GPU name:
- notable GPU processes:

VRAM free/used:
- total:
- used:
- free:

llama-server running yes/no:
- pgrep summary:
- /v1/models response summary:
- if running, do I understand M31.2 stop/start plan? yes/no:

Docker containers visible:
- docker ps summary:
- docker compose ps summary:
- media/comfy containers visible yes/no:

ComfyUI/media scripts found:
- list short paths:

Image/media docs found:
- list short paths:

Flux/CLIP/VAE model files found:
- Flux:
- CLIP:
- VAE:
- safetensors:
- GGUF:

Missing model files:
- list missing or uncertain files:

Gateway health:
- /gateway/health summary:
- runtime profile summary available yes/no:

PC-2 health if used:
- ping 192.168.50.2:
- Memory API 8101:
- Embed Worker 8102:
- Qdrant 6333:

Go/no-go decision:
- GO / NO-GO:
- reason:

Questions/blockers:
- question 1:
- question 2:
```

Do not paste secrets, real `.env` files, private tokens, huge logs, generated images, or model files.
