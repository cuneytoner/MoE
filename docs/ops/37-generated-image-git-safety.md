# 37 Generated Image Git Safety

Generated images, model files, checkpoints, and media artifacts must stay out of Git. The repo is source-only.

## What Must Not Be Committed

Do not commit:

- `.png`, `.jpg`, `.jpeg`, `.webp` generated outputs
- `.safetensors`, `.gguf`, `.ckpt`, `.pt`, `.pth` model/checkpoint files
- Runtime logs, PID files, temporary workflow outputs, or generated media folders
- Anything copied from `~/MoE/runtime` or `~/MoE_Models_Backup`

## Check Staged And Tracked Files

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git diff --cached --stat
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: generated media/model extensions do not appear as tracked or staged repo files.

## Unstage Generated Files

If a generated file was accidentally staged, unstage it by replacing `<path>` with the exact path from `git status`.

### Run on PC-1

```bash
git restore --staged <path>
```

Expected good sign: `git status --short` no longer shows the file as staged.

## Remove Accidental Generated Files From Working Tree

Only remove a generated file from the repo working tree when you are certain it is not needed and you have copied or recorded any evidence you need. Use a manual placeholder, not a broad delete.

### Run on PC-1

```bash
# Manual only: replace <path> with one known generated file after reviewing it.
# rm <path>
```

Expected good sign: you remove only the reviewed generated file, never a whole runtime/model folder.

## Document Outputs Without Committing Binaries

Record:

- Runtime output directory
- Filename
- Image dimensions if known
- Prompt summary if safe to share
- Error text or prompt ID if generation failed

Use [36-first-real-image-generation-evidence-template.md](36-first-real-image-generation-evidence-template.md) for the review packet.

## After First Successful Generation

The first successful real image generation produced a PNG under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

This generated image path is outside the repo. That is the expected safe layout.

After generation, run:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
```

Expected good sign: `git status --short` does not show generated PNGs.

If it does show a generated PNG, stop and inspect before committing. Do not stage or commit generated image binaries.

## Recommended Output Folder Policy

- Generated images belong under `~/MoE/runtime/media/outputs/images`.
- Model files belong under `~/MoE_Models_Backup`.
- Source docs/scripts/config examples belong in this repo.
- If a generated image is useful for a report, reference its runtime path instead of committing the binary.
