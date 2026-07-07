# 53 Media Dashboard Review Template

Use this copy/paste template to review generated outputs as surfaced by media dashboard status.

Do not commit generated image binaries. Record paths and metadata only.

## Blank Review Template

```text
Date/time:
Command used:
Dashboard status:
Safety flags:
Services status:
latest_images count:
Newest image name:
Newest image path:
Newest image size:
Filesystem confirmation:
Git safety result:
Notes:
Questions/blockers:
```

## Suggested Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make media-dashboard-status
```

### Run on PC-1

```bash
make image-latest
```

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -30
```

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

## Review Notes

When reviewing `latest_images`, check:

- The newest filename matches the expected output.
- The path points under runtime media outputs.
- The file size is not suspiciously small.
- Git does not show generated media or model files.
- Dashboard safety flags remain read-only.
