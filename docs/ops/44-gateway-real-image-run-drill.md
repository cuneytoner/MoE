# 44 Gateway Real Image Run Drill

This drill is the beginner-friendly guarded path for a real image generation run through the full Gateway/media pipeline.

It follows the direct ComfyUI first-image success and prepares the operator to validate Gateway, Media API, Media Worker, PC-2 Prompt Interpreter, and the ComfyUI host bridge before any real generation command is run.

## What This Drill Does

- Verifies repo and Git safety before image work.
- Checks PC-2 Prompt Interpreter reachability.
- Checks the media dry stack and image readiness.
- Checks ComfyUI host health and VRAM status.
- Runs one final dry-run before real generation.
- Shows the guarded real command that the operator runs manually.
- Shows how to inspect latest runtime image outputs.
- Returns the machine to coding mode.
- Verifies generated images and model files are not in Git.

## What This Drill Does NOT Do

- It does not make Gateway auto-run shell commands.
- It does not bypass `APPLY=1`.
- It does not bypass `MEDIA_REAL_GENERATION_ENABLED=true`.
- It does not switch models automatically.
- It does not control Docker from Gateway.
- It does not commit generated images.
- It does not commit model files.

## Direct ComfyUI First-Image vs Gateway Real Image Run

The direct first-image path proved that ComfyUI and Flux Schnell can produce a real image on PC-1.

Successful direct output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

The Gateway/media path adds more services around the same guarded generation idea:

| Path | Main purpose | Safety shape |
| --- | --- | --- |
| Direct ComfyUI first-image | Prove the local ComfyUI/Flux workflow works | Operator-run script, explicit `APPLY=1` |
| Gateway/media real image run | Prove Gateway, Media API, Media Worker, Prompt Interpreter, and ComfyUI bridge are aligned | Operator-run script, explicit `APPLY=1` and `MEDIA_REAL_GENERATION_ENABLED=true` |

Gateway must remain advisory and API-facing. The operator still runs the real command manually from PC-1.

## Preconditions

Expected state before running this drill:

- You are on PC-1.
- M31.4 direct first real image generation succeeded.
- M31.5 output handling and Git safety docs were reviewed.
- M31.6 workflow inventory was reviewed.
- PC-2 Prompt Interpreter is expected at `http://192.168.50.2:8230`.
- Media API is expected to be reachable from Gateway container as `http://media-api:8300`.
- Media Worker is expected to be reachable from Gateway container as `http://media-worker:8310`.
- ComfyUI is expected to be reachable from containers through `http://host.docker.internal:8188`.
- `media_real_generation_enabled=false` by default.
- `gateway_real_allowed=false` by default.
- Real generation remains explicitly guarded.

Do not run the real command until dry-run and readiness are green. Do not run if llama-server is still consuming VRAM.

## Step 1: Verify Coding Repo And Git State

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: only source changes you understand are visible, and no generated media appears in the repo.

## Step 2: Verify PC-2 Prompt Interpreter

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8230/health | jq .
```

Expected good sign: PC-2 Prompt Interpreter responds with a healthy status.

If this fails, use [46-gateway-real-image-troubleshooting.md](46-gateway-real-image-troubleshooting.md).

## Step 3: Verify Media Dry Stack

### Run on PC-1

```bash
make media-dashboard-status
make image-readiness
make image-dry-run
```

Expected good sign: the media dashboard reports the expected services, image readiness reports `ready_for_real_generation=true`, and dry-run succeeds without real generation.

## Step 4: Verify ComfyUI Bridge

### Run on PC-1

```bash
make comfyui-health
make comfyui-vram-status
```

Expected good sign: ComfyUI responds, and VRAM status does not show llama-server consuming image-generation VRAM.

## Step 5: Verify Image Readiness

If Step 3 already passed, this is a deliberate second look before real generation.

### Run on PC-1

```bash
make image-readiness
```

Expected good sign: readiness remains green, with real generation still guarded by environment flags.

## Step 6: Run Dry-Run One More Time

### Run on PC-1

```bash
make image-dry-run
```

Expected good sign: dry-run creates or reports a dry-run job path only. It must not generate a real image.

## Step 7: Run Guarded Gateway/Media Real Image Command

Only run this when every previous check is green and you intentionally want a real image generation attempt.

### Run on PC-1

```bash
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true scripts/image/image-real-run.sh
```

Expected good sign: the command verifies gates, submits the media path, waits for the job, and reports output information. The operator runs this manually; Gateway must not auto-run shell commands.

## Step 8: Inspect Latest Images

### Run on PC-1

```bash
make image-latest
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -20
```

Expected good sign: any new PNG appears under `/home/cuneyt/MoE/runtime/media/outputs/images`, not inside the repo.

## Step 9: Safe Shutdown / Return To Coding Mode

### Run on PC-1

```bash
APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh
```

Expected good sign: image mode shuts down safely and the coding model is restored.

After shutdown, verify Gateway/coding health if needed:

### Run on PC-1

```bash
make model-health
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

## Step 10: Git Safety Check

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: generated images, model files, and checkpoints do not appear as tracked or staged repo files.

If a generated image appears in Git, stop and inspect before committing.

## Troubleshooting

Use [46-gateway-real-image-troubleshooting.md](46-gateway-real-image-troubleshooting.md) for known failure cases.

When reporting a blocker, include:

- The step number.
- The exact command.
- The last 30 to 80 lines of output.
- PC-2 Prompt Interpreter status.
- Media dashboard status.
- Image readiness result.
- Dry-run result.
- ComfyUI health.
- Git status.

Do not use destructive cleanup commands. Do not use `docker volume prune`. Do not delete generated outputs or model files as a default fix.
