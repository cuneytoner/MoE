# 34 Image Existing Script Map

This page maps existing image/media scripts and Make targets before M31.4. It helps operators see which commands are readiness/planning and which paths are guarded real generation.

Gateway must not auto-run shell commands. Real image generation remains explicit operator action.

| Purpose | Make target | Script | Real generation? | Guard |
| --- | --- | --- | --- | --- |
| Guided image readiness | `make image-readiness` | `scripts/image/image-readiness.sh` | No | Readiness/check only |
| Guided image dry-run | `make image-dry-run` | `scripts/image/image-dry-run.sh` | No | Dry-run only |
| Prepare image mode | `make image-mode-prepare` | `scripts/image/image-mode-prepare.sh` | No image generation | Real mode preparation requires `APPLY=1`; `STOP_LLM=1` uses `make model-stop`, not `pkill` |
| Real image run | `make image-real-run` | `scripts/image/image-real-run.sh` | Yes, when enabled | Requires `APPLY=1` and `MEDIA_REAL_GENERATION_ENABLED=true` |
| List latest images | `make image-latest` | `scripts/image/image-latest.sh` | No | Read-only listing |
| Safe shutdown / return | `make image-safe-shutdown` | `scripts/image/image-safe-shutdown.sh` | No image generation | Guarded by `APPLY=1`; optional `START_LLM=1` |
| Full image cycle | `make image-full-cycle` | `scripts/image/image-full-cycle.sh` | Yes, when fully confirmed | Requires `APPLY=1` and `CONFIRM_IMAGE_FULL_CYCLE=1`; real generation remains guarded |
| Start ComfyUI | `make comfyui-up` | `scripts/comfyui-up.sh` | No image generation by itself | Operator-run service start |
| Stop ComfyUI | `make comfyui-down` | `scripts/comfyui-down.sh` | No | Operator-run service stop |
| Check ComfyUI health | `make comfyui-health` | `scripts/comfyui-health.sh` | No | Health check |
| Check VRAM status | `make comfyui-vram-status` | `scripts/comfyui-vram-status.sh` | No | Read-only status |
| Flux smoke test | `make comfyui-flux-smoke-test` | `scripts/comfyui-flux-smoke-test.sh` | No real image generation expected | Read-only/readiness smoke check |
| First image plan | `make comfyui-first-image-plan` | `scripts/comfyui-first-image.sh` | No | Plan mode by default |
| First image apply | `make comfyui-first-image-apply` | `scripts/comfyui-first-image.sh` | Yes, if service accepts it | Requires `APPLY=1`; operator-reviewed real action |

## Key Safety Notes

- Plan and dry-run targets do not generate images.
- Real generation requires explicit guards such as `APPLY=1` and/or `MEDIA_REAL_GENERATION_ENABLED=true`.
- Full cycle requires `APPLY=1` and `CONFIRM_IMAGE_FULL_CYCLE=1`.
- `STOP_LLM=1` in `scripts/image/image-mode-prepare.sh` uses `make model-stop`, not `pkill`.
- Gateway must not auto-run shell commands.
- Generated images, model files, checkpoints, and `.safetensors` files must stay out of Git.

## M31.4 First Real Image Flow

Use this order for the first controlled real image generation drill:

1. `make image-readiness`
2. `make image-dry-run`
3. `make comfyui-first-image-plan`
4. `APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh`
5. `APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh`
6. `make image-latest`
7. `make image-safe-shutdown`
8. Return to coding mode with `make model-start MODEL=qwen-coder-14b-fast` and `make model-health`.

Steps 4 and 5 are real operator actions. Do not run them unless you intentionally want image mode preparation and real generation.

## Gateway/media Real Run Path

Use this order for the guarded full Gateway/media path:

1. `make image-readiness`
2. `make image-dry-run`
3. `APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh`
4. `make image-latest`
5. `APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh`

Step 3 is a real operator action. Do not run it until readiness and dry-run are green, and do not run it if llama-server is still consuming VRAM.

## Before M31.4

Read:

- [31-first-image-dry-run-evidence-review.md](31-first-image-dry-run-evidence-review.md)
- [32-first-image-dry-run-evidence-template.md](32-first-image-dry-run-evidence-template.md)
- [33-first-image-dry-run-review-checklist.md](33-first-image-dry-run-review-checklist.md)
- [35-first-real-image-generation-drill.md](35-first-real-image-generation-drill.md)
