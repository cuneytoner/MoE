# 35 First Real Image Generation Drill

This drill is the first controlled path from image readiness into a real image generation attempt. It is for a human operator on PC-1 after completing the M31.0 through M31.3 safety and dry-run checks.

## What This Drill Does

- Confirms the repo is clean enough to operate from.
- Runs readiness and dry-run checks first.
- Shows the exact guarded commands for image mode preparation and real generation.
- Returns the machine to coding mode afterward.
- Checks that generated media and model files are not accidentally staged for Git.

## What This Drill Does NOT Do

- It does not make Gateway run commands.
- It does not automatically stop or start llama-server.
- It does not switch models automatically.
- It does not bypass the image generation guards.
- It does not require PC-2 unless memory or worker services are needed for your specific workflow.

## Safety Contract

Real image generation requires explicit operator intent. Do not run the `APPLY=1` commands unless you intentionally want real generation.

- Do not stage generated images.
- Do not stage model files.
- Do not use `docker volume prune`.
- Do not kill random processes.
- Gateway does not run these commands.
- PC-2 is not required for local image generation unless memory/worker services are needed.

## Preconditions

Read these first:

- [31-first-image-dry-run-evidence-review.md](31-first-image-dry-run-evidence-review.md)
- [33-first-image-dry-run-review-checklist.md](33-first-image-dry-run-review-checklist.md)
- [34-image-existing-script-map.md](34-image-existing-script-map.md)

Expected state:

- You are on PC-1.
- You have reviewed GPU/VRAM status.
- You understand that `STOP_LLM=1` uses `make model-stop`.
- You know where generated outputs should live under runtime folders, not in Git.

## Step 1: Confirm Repo And Git State

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: no surprise generated files, no root-level `@...` files, and only source changes you understand.

## Step 2: Run Image Readiness

### Run on PC-1

```bash
make image-readiness
```

Expected good sign: readiness output points to the expected PC-1 media/runtime locations and does not report a blocker you cannot explain.

## Step 3: Run Image Dry-Run

### Run on PC-1

```bash
make image-dry-run
```

Expected good sign: the dry-run completes without real generation and tells you what would be checked or submitted.

## Step 4: Review Existing Script Map

### Run on PC-1

```bash
make comfyui-first-image-plan
```

Expected good sign: the plan prints the ComfyUI first image settings and says no workflow will be submitted without `APPLY=1`.

Also review [34-image-existing-script-map.md](34-image-existing-script-map.md) before moving to real preparation.

## Step 5: Prepare Image Mode With Explicit Operator Approval

Only run this when you intentionally want to prepare real image mode.

### Run on PC-1

```bash
APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh
```

Expected good sign: the script uses `make model-stop`, starts the guarded media/ComfyUI services, and reruns readiness. Gateway still does not stop llama-server.

## Step 6: Run First Real Generation With Explicit Operator Approval

Only run this when real generation is intentional.

### Run on PC-1

```bash
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh
```

Expected good sign: the script verifies real-generation gates, checks ComfyUI and Flux readiness, runs the media image job, and prints latest image information.

## Step 7: Find Latest Generated Image

### Run on PC-1

```bash
make image-latest
```

Expected good sign: latest output paths point under runtime/media output locations, not inside the Git repo.

## Step 8: Safe Shutdown

### Run on PC-1

```bash
make image-safe-shutdown
```

Expected good sign: image/media mode returns to a safe state. If the script is in plan mode, follow its guarded instructions deliberately.

## Step 9: Return To Coding Mode

### Run on PC-1

```bash
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: llama-server is healthy, Gateway is healthy, and `/v1/models` responds through Gateway.

## Step 10: Git Safety Check

### Run on PC-1

```bash
git status --short
find . -maxdepth 4 -type f | grep -Ei 'png|jpg|jpeg|webp' || true
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: no generated image files, model files, checkpoints, or root-level `@...` files are in the repo.

## What Evidence To Paste Back If Blocked

Paste:

- Which step failed.
- The exact command you ran.
- The last 30 to 80 lines of output.
- Whether llama-server was running.
- Whether `make image-readiness`, `make image-dry-run`, and `make comfyui-first-image-plan` passed.
- Any generated output path, if one exists.
- `git status --short` after the drill.
