# 63 Prompt Quality Review Template

Use this template to review future improved prompt outputs.

Do not commit generated image binaries. Record paths and notes only.

## Review Template

```text
Date/time:
Prompt ID/variant:
Prompt text:
Negative prompt if used:
Size:
Steps:
Seed:
Output path:
Output filename:
File size:
Does it match pergola geometry?
Does it show covered roof?
Does it show practical construction?
Does it avoid luxury/render look?
What improved?
What failed?
Keep/reject:
Next edit:
```

## Review Guidance

For the next pergola prompt round, prioritize:

- Practical project fit
- Covered roof clarity
- Rain/wetness clarity for rain variants
- Visible joinery and hardware for technical variants
- Avoidance of polished showroom/render look

## Git Safety Check

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: no generated image or model files are tracked by Git.
