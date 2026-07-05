# 24 Image First Dry Run Plan

This plan prepares the first dry-run only image pipeline check. Dry-run means no real image generation.

## What Dry-Run Means

- Inspect scripts.
- Inspect docs.
- Inspect Docker state.
- Inspect GPU state.
- Confirm model candidates.
- Do not create images.
- Do not start real generation.

## What To Inspect Before Real Image Generation

- Existing image/media scripts.
- Existing image/media docs.
- Docker services currently running.
- GPU and VRAM state.
- Whether llama-server is running.
- Model inventory under `~/MoE_Models_Backup/`.

## Inspection Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
find scripts -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
find docs -maxdepth 3 -type f | grep -Ei 'image|comfy|flux|media'
docker ps
nvidia-smi
```

Expected good signs:

- Relevant scripts are listed.
- Relevant docs are listed.
- Docker state is visible.
- GPU state is visible.

## Which Scripts Look Relevant

Look for scripts with names containing:

- `image`
- `comfy`
- `flux`
- `media`

Then open the script before running anything. Check whether it is a readiness check, dry-run plan, or real generation path.

## Which Services Might Be Used

- PC-1 GPU.
- PC-1 llama-server when returning to coding mode.
- PC-1 Gateway for media planning or API checks.
- ComfyUI runtime after a later startup checklist.
- PC-2 services only if memory/database support is needed.

## How To Verify No Real Generation Happened

- No new generated images should appear in the source repo.
- No generated media should be committed.
- Dry-run output should describe plans or readiness, not final images.
- If a script says it requires `APPLY=1` or a real-generation flag, do not run that flag during dry-run planning.

## What Evidence To Paste Back Into ChatGPT/Codex

Paste summaries, not huge logs:

- Which scripts were found.
- Which docs were found.
- Whether `nvidia-smi` showed free VRAM.
- Whether llama-server was running.
- Which model candidates were found.
- Any errors from readiness checks.

Do not paste secrets, real `.env` files, or huge model listings.

## Not Included Yet

This document intentionally does not include a real generation command. That belongs in M31.1 or a later guarded runbook.
