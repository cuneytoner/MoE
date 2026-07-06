# 43 ComfyUI Workflow Change Log

Use this manual changelog template for future ComfyUI workflow edits or parameter changes.

Generated image binaries must not be committed. Record paths and metadata instead.

## Blank Change Record

```text
Date/time:
Git commit:
Workflow file path:
What changed:
Why changed:
Prompt:
Size:
Steps:
Seed:
Output path:
Result:
Rollback notes:
Git safety check:
```

## Example Based On First Successful Run

```text
Date/time: 2026-07-06 13:34:41 local time, from output filename
Git commit: not recorded in this template
Workflow file path: /home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json
What changed: first successful real Flux Schnell run recorded
Why changed: establish known-good baseline after M31.4
Prompt: realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
Size: 512x512
Steps: 4
Seed: 1783334081
Output path: /home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
Result: success
Rollback notes: keep this as the baseline before future workflow edits
Git safety check: generated PNG stayed outside the repo
```

## What To Record

Record enough detail that a future operator can understand what happened:

- The exact workflow file path.
- The exact parameter values.
- Whether the change was a prompt-only change or a workflow JSON change.
- The output path and result.
- How to roll back if the change made output worse.
- The Git safety result.

## Git Safety Check

Before committing source changes after any workflow run:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: generated images, model files, and checkpoints do not appear as tracked or staged repo files.
