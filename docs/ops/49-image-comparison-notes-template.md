# 49 Image Comparison Notes Template

Use this manual template to compare generated prompt variants.

Do not commit generated image binaries. Record paths and notes only.

## Blank Template

```text
Date/time:
Workflow:
Base prompt:
Variant prompt:
Size:
Steps:
Seed:
Output filename:
Output path:
Visual notes:
What improved:
What got worse:
Keep / reject:
Next prompt idea:
Git safety result:
```

## Comparison Tips

Compare one thing at a time:

- Framing
- Lighting
- Weather
- Material
- Technical clarity

Avoid judging too many changes at once. If a variant changes lighting and weather and camera angle, split it into smaller future variants.

## Git Safety Check

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: generated image binaries and model files do not appear as tracked or staged repo files.
