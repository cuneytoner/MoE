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

## Before M31.4

Read:

- [31-first-image-dry-run-evidence-review.md](31-first-image-dry-run-evidence-review.md)
- [32-first-image-dry-run-evidence-template.md](32-first-image-dry-run-evidence-template.md)
- [33-first-image-dry-run-review-checklist.md](33-first-image-dry-run-review-checklist.md)
