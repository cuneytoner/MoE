# 45 Gateway Real Image Evidence Template

Use this copy/paste template after a guarded Gateway/media real image run.

Do not commit generated image binaries. Record paths and metadata only.

## Evidence Template

```text
Date/time:
Git commit:
PC-2 Prompt Interpreter status:
Media dashboard before run:
Image readiness result:
Dry-run job id:
Real command used:
Real media job id if present:
Output path:
Output filename:
File size:
ComfyUI status after run:
Safe shutdown result:
Coding model restored yes/no:
Gateway health after restore:
Git safety result:
Errors/blockers:
```

## Suggested Evidence Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git rev-parse --short HEAD
```

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8230/health | jq .
```

### Run on PC-1

```bash
make media-dashboard-status
make image-readiness
make image-dry-run
make image-latest
```

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

## Notes

- The real command should be recorded exactly as run.
- Output paths should point under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- If no real media job id is printed, write `not printed` instead of guessing.
- If a generated image appears in Git status, stop before committing and use [37-generated-image-git-safety.md](37-generated-image-git-safety.md).
