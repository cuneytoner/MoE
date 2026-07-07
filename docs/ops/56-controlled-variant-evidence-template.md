# 56 Controlled Variant Evidence Template

Use this evidence template for the whole controlled prompt variant session.

Do not commit generated image binaries. Record paths and metadata only.

## Session Evidence

```text
Date/time:
Git commit:
Operator:
PC-1 readiness before run:
PC-2 Prompt Interpreter status:
ComfyUI status:
VRAM before first variant:
Variant count:
Variant table:
Latest images after run:
Dashboard review result:
Safe shutdown result:
Coding model restored yes/no:
Git safety result:
Errors/blockers:
```

## Variant Table Template

```text
Variant ID | Variant name | Prompt | Output path | File size | Result | Notes
--- | --- | --- | --- | --- | --- | ---
A |  |  |  |  |  |
B |  |  |  |  |  |
C |  |  |  |  |  |
D |  |  |  |  |  |
E |  |  |  |  |  |
```

## Suggested Evidence Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git rev-parse --short HEAD
```

### Run on PC-1

```bash
make image-latest
make media-dashboard-status
```

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: generated image binaries and model files do not appear as tracked or staged repo files.
