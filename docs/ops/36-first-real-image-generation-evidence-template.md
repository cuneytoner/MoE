# 36 First Real Image Generation Evidence Template

Use this after the first real image generation drill. Paste the completed template into ChatGPT/Codex when asking for review.

Do not include generated image binaries in Git. Describe output paths and filenames instead.

## Collection Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git rev-parse --short HEAD
git status --short
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
make image-latest
find . -maxdepth 4 -type f | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: output files are under runtime/media folders, and Git does not show generated images or model files.

## Evidence Template

```text
Date/time:
Commit hash before drill:

PC-1 GPU summary:

Was llama-server stopped?
Yes/No:
How confirmed:

Image readiness result:

Image dry-run result:

ComfyUI plan result:

Real generation command used:

Output path:

Output filename:

Image dimensions if known:

Any errors:

Was safe shutdown run?

Was coding mode restored?

Git status after drill:

Files that must NOT be committed:

Questions/blockers:
```

## Notes

- Real generation should have used the guarded `APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true` path.
- Image mode preparation should have used the guarded `APPLY=1 STOP_LLM=1` path if llama-server needed to stop.
- Do not paste secrets, `.env` values, or large binary files.
