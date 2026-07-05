# 23 Image Model Inventory Guide

This guide explains which image-related model files are expected and where to look. It does not download models.

## Model Root

Model files belong under:

```text
~/MoE_Models_Backup/
```

They do not belong in the source repo.

## Flux Model Files

Flux model files are expected to live under `~/MoE_Models_Backup/` or a reviewed subfolder. Names may include `flux`.

## CLIP Files

CLIP files are expected under `~/MoE_Models_Backup/` or a reviewed subfolder. Names may include `clip`.

## VAE Files

VAE files are expected under `~/MoE_Models_Backup/` or a reviewed subfolder. Names may include `vae`.

## safetensors Files

`.safetensors` files may be image checkpoints, LoRA files, or related model assets. They must not be committed to Git.

## GGUF Files

GGUF files are used for local coding/model runtime and may matter when returning from image mode to coding mode.

## What Belongs In `~/MoE_Models_Backup/`

- GGUF coding models.
- Flux files.
- CLIP files.
- VAE files.
- `.safetensors` files.
- Other reviewed model assets.

## What Must NOT Be Committed To Git

- model files.
- `.safetensors`.
- generated images.
- checkpoints.
- downloaded archives.
- real `.env` files.

## List Models Safely

### Run on PC-1

```bash
find ~/MoE_Models_Backup -maxdepth 3 -type f | sort
find ~/MoE_Models_Backup -maxdepth 3 -type f | grep -Ei 'flux|clip|vae|safetensors|gguf' || true
du -sh ~/MoE_Models_Backup/* 2>/dev/null | sort -h
```

Expected good signs:

- Files are listed under `~/MoE_Models_Backup/`.
- Image-related candidates appear if installed.
- Large folders/files are visible in the size summary.

## Document Missing Files Without Downloading Automatically

If a required file is missing:

1. Write down the missing model name.
2. Write down the expected folder.
3. Confirm whether it is already on another disk or backup.
4. Do not download automatically.
5. Do not put downloaded files in the repo.

Use [21-image-pipeline-entry-plan.md](21-image-pipeline-entry-plan.md) to track open questions before real generation.
