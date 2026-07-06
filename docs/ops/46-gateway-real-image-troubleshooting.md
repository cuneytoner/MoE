# 46 Gateway Real Image Troubleshooting

This guide covers common blockers in the full Gateway/media image path.

Use safe checks first. Do not use destructive cleanup commands as a default fix.

## Prompt Interpreter Unavailable

Symptom: PC-2 Prompt Interpreter health check fails or times out.

Likely cause: PC-2 worker is down, PC-2 network is unavailable, or port `8230` is not serving.

Check command:

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8230/health | jq .
```

Safe next step: Start or inspect the PC-2 Prompt Interpreter using the PC-2 runbooks, then rerun the health check.

What not to do: Do not edit Gateway code, change Docker Compose, or bypass prompt interpretation safety just to make the check pass.

## media_api ConnectError

Symptom: Gateway/media status reports a Media API connection error.

Likely cause: Media API container is down, not on the expected Docker network, or Gateway cannot resolve `http://media-api:8300`.

Check command:

### Run on PC-1

```bash
make media-dashboard-status
```

Safe next step: Use the media startup runbooks to restore the dry media stack, then rerun `make media-dashboard-status`.

What not to do: Do not add Gateway shell execution, edit Docker Compose during the run, or run real generation while Media API is unavailable.

## media_worker ConnectError

Symptom: Media API or dashboard reports a Media Worker connection error.

Likely cause: Media Worker container is down, unhealthy, or unreachable at `http://media-worker:8310`.

Check command:

### Run on PC-1

```bash
make media-dashboard-status
```

Safe next step: Restore the media dry stack with the existing operator runbooks, then rerun image readiness and dry-run checks.

What not to do: Do not skip Media Worker and do not manually copy generated outputs into runtime to fake success.

## ComfyUI Unavailable From Host

Symptom: ComfyUI host health check fails.

Likely cause: ComfyUI is not running on PC-1, is still starting, or is not listening on port `8188`.

Check command:

### Run on PC-1

```bash
make comfyui-health
```

Safe next step: Start or inspect ComfyUI using the existing ComfyUI startup checklist, then rerun health and VRAM checks.

What not to do: Do not run the guarded real command while ComfyUI health is failing.

## ComfyUI Unavailable From Container Bridge

Symptom: Host ComfyUI works, but the media stack cannot reach `http://host.docker.internal:8188`.

Likely cause: Container bridge configuration or host alias resolution is not available to the media services.

Check command:

### Run on PC-1

```bash
make image-readiness
```

Safe next step: Review the readiness output and media dashboard status. Keep the fix in a separate reviewed milestone if Docker networking changes are needed.

What not to do: Do not alter Docker Compose during a real run attempt, and do not make Gateway execute host commands.

## ready_for_real_generation=false

Symptom: Image readiness says real generation is not ready.

Likely cause: One or more required services, model links, workflow files, or safety gates are not in the expected state.

Check command:

### Run on PC-1

```bash
make image-readiness
```

Safe next step: Read the readiness failure, fix the specific blocker, then rerun readiness and dry-run.

What not to do: Do not force the real command while readiness is false.

## MEDIA_REAL_GENERATION_ENABLED Missing

Symptom: Real image run refuses to generate because `MEDIA_REAL_GENERATION_ENABLED=true` is missing.

Likely cause: The real-generation environment guard was not intentionally set.

Check command:

### Run on PC-1

```bash
make image-dry-run
```

Safe next step: If readiness and dry-run are green and real generation is intentional, use the documented guarded command exactly.

What not to do: Do not remove the environment guard from scripts or service code.

## APPLY Missing

Symptom: Real run command stays in plan/dry mode or refuses to proceed because `APPLY=1` is missing.

Likely cause: The operator did not explicitly approve the real action.

Check command:

### Run on PC-1

```bash
make image-dry-run
```

Safe next step: Review the drill again. Only run with `APPLY=1` when you intentionally want real generation.

What not to do: Do not make scripts default to apply mode.

## No New Image Detected

Symptom: The real command finishes but `make image-latest` does not show a new PNG.

Likely cause: The job failed, output discovery missed the file, or strict new output detection prevented an old file from being counted.

Check command:

### Run on PC-1

```bash
make image-latest
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -20
```

Safe next step: Review the real command output and media job status. Record the blocker in [45-gateway-real-image-evidence-template.md](45-gateway-real-image-evidence-template.md).

What not to do: Do not copy an older PNG into the output folder to make the run appear successful.

## Image Generated But Not Surfaced To Runtime Output Folder

Symptom: ComfyUI appears to generate an image, but the expected runtime output folder does not show it.

Likely cause: Output folder mapping, filename prefix, or output discovery is misaligned.

Check command:

### Run on PC-1

```bash
make image-latest
```

Safe next step: Inspect the job output text and workflow output settings. Keep any script or mapping fix in a separate reviewed source change.

What not to do: Do not move model files, delete output folders, or edit workflow JSON casually.

## Coding Model Not Restored After Safe Shutdown

Symptom: After image shutdown, coding model health fails.

Likely cause: llama-server did not restart, is still loading, or the selected coding model failed health checks.

Check command:

### Run on PC-1

```bash
make model-health
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Safe next step: Follow [30-image-mode-return-to-coding.md](30-image-mode-return-to-coding.md) and retry the explicit coding-mode start path.

What not to do: Do not make Gateway switch models automatically.

## Generated Image Accidentally Appears In Repo

Symptom: `git status --short` shows a generated image or model artifact.

Likely cause: A runtime output or model file was copied into the source repo.

Check command:

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Safe next step: Stop before committing. Use [37-generated-image-git-safety.md](37-generated-image-git-safety.md) to inspect and unstage if needed.

What not to do: Do not commit generated images, model files, checkpoints, or broad cleanup changes.
