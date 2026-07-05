# 18 Image Mode Entry Checklist

This is the bridge from coding mode to future image/media work. It is readiness-only. It does not run real image generation.

Read next:

- [19 Media Readiness Map](19-media-readiness-map.md)
- [20 Image Mode Safety Rules](20-image-mode-safety-rules.md)
- [21 Image Pipeline Entry Plan](21-image-pipeline-entry-plan.md)

## When Do We Move From Coding Mode To Image Mode?

Move to image mode when the task needs PC-1 GPU VRAM for ComfyUI, Flux, image models, video, 3D, or media workflows.

Stay in coding mode when you only need Continue, Gateway, llama-server, docs, tests, or app code work.

## What Must Be Checked Before Image Generation?

- PC-1 GPU status.
- Whether llama-server is running on port `8000`.
- Docker services currently running.
- Image/media model files or candidates under `~/MoE_Models_Backup`.
- Media runtime folders and ComfyUI layout readiness.

## What Should Happen To llama-server?

llama-server uses PC-1 GPU VRAM. Image generation may need that VRAM. The operator may manually stop llama-server before real image work, but this checklist does not stop anything automatically.

## Which Services Use VRAM?

- llama-server on PC-1 can use VRAM for coding models.
- ComfyUI and Flux/image workflows can use VRAM for image generation.
- Future video/3D/media work may also use VRAM.

## Which Model Files Should Exist?

Image work may need Flux, CLIP, VAE, `.safetensors`, or other image assets. Coding mode uses GGUF models under `~/MoE_Models_Backup/`.

## Existing Image Readiness Docs And Scripts

- [guided-image-generation.md](../guided-image-generation.md)
- [image-generation.md](../image-generation.md)
- [media-lab.md](../media-lab.md)
- `make check-media-layout`
- `make check-image-models`
- `make check-comfyui-layout`
- `make check-comfyui-runtime`
- `make comfyui-vram-status`
- `make image-readiness`
- `make image-dry-run`

## Readiness Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
find ~/MoE_Models_Backup -maxdepth 2 -type f | grep -Ei 'flux|clip|vae|gguf|safetensors' || true
```

Expected good sign: GPU state is visible, the operator knows whether llama-server is running, Docker state is visible, and relevant model candidates are listed if present.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-media-layout
make check-image-models
make check-comfyui-layout
make comfyui-vram-status
make image-readiness
```

Expected good sign: readiness commands complete and print guided status without running real image generation.

## What Is Still Future Work?

- Full image processing runbook after M30.4/M31.0.
- Real image generation operator flow.
- Video/3D/media runtime service matrix.
- Any guarded automation for switching between coding and image modes.

No automatic model switching or automatic image generation is included here.
