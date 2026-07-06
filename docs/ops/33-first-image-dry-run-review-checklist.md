# 33 First Image Dry Run Review Checklist

Use this checklist before approving M31.4 First Real Image Generation Drill.

## Review Checklist

- [ ] Repo is clean enough for dry-run.
- [ ] No `@*` pasted files are present.
- [ ] GPU is visible.
- [ ] VRAM state is understood.
- [ ] llama-server state is understood.
- [ ] If llama-server is running, operator understands M31.2 stop/start plan.
- [ ] Image scripts are located.
- [ ] Image docs are located.
- [ ] Model files are located.
- [ ] Missing model files are listed.
- [ ] Gateway is healthy or Gateway status is understood.
- [ ] PC-2 support services were checked if required.
- [ ] No real generation command has been run.
- [ ] No generated image files are committed.
- [ ] No model files are committed.
- [ ] M31.4 can proceed only with explicit operator approval.

## Reviewer Notes

If any item is unchecked, stay in evidence review. Do not move to real image generation.

If model files are missing, document the missing files and expected location. Do not download automatically.

If VRAM state is unclear, return to [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md).

If llama-server state is unclear, return to [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md).
