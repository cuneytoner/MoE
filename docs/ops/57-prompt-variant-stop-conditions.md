# 57 Prompt Variant Stop Conditions

Stop variant generation when safety, output location, or operator intent is unclear.

This page lists common stop conditions and safe next steps.

| Stop condition | Safe next step |
| --- | --- |
| Free VRAM too low | Stop generation planning, keep image mode idle, and review `make comfyui-vram-status`. |
| llama-server still running during image mode | Stop before real generation and use the guarded image mode preparation path. |
| ComfyUI health fails | Stop and run `make comfyui-health`; do not submit another generation. |
| Media API or Media Worker fails | Stop and review `make image-readiness` and `make media-dashboard-status`. |
| Output path unclear | Stop and confirm outputs belong under `/home/cuneyt/MoE/runtime/media/outputs/images`. |
| No new image detected | Stop and inspect `make image-latest` before running another variant. |
| Image files appear inside repo | Stop before commit and use [37-generated-image-git-safety.md](37-generated-image-git-safety.md). |
| GPU temperature unexpectedly high | Stop generation and let the operator inspect GPU status before continuing. |
| Repeated failed generations | Stop the session and record blockers in [56-controlled-variant-evidence-template.md](56-controlled-variant-evidence-template.md). |
| Operator is unsure what command will do | Stop and read [54-controlled-prompt-variant-generation.md](54-controlled-prompt-variant-generation.md) before continuing. |

If the Git safety command shows many unrelated prompt files, verify that the grep pattern is extension-anchored:

```bash
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

## Safe Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make image-readiness
make comfyui-health
make comfyui-vram-status
make media-dashboard-status
git status --short
```

## What Not To Do

- Do not run another variant to "see if it fixes itself."
- Do not start an automatic loop.
- Do not run overnight generation.
- Do not remove safety guards.
- Do not make Gateway execute shell commands.
- Do not alter Docker Compose during a variant session.
- Do not move generated files into the repo.
- Do not delete generated images as a default response.
