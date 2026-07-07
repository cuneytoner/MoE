# 54 Controlled Prompt Variant Generation

This guide explains how to generate 3 to 5 prompt variants manually and safely.

It is operator-controlled. It does not add automatic batch generation.

## What This Guide Is For

- Prepare a small controlled variant session.
- Keep first variants at known-safe settings.
- Run one variant at a time.
- Inspect output after each variant.
- Stop when safety checks or output review are unclear.
- Record evidence without committing generated image binaries.

## What This Guide Does NOT Do

- It does not run real image generation by itself.
- It does not submit ComfyUI workflows automatically.
- It does not add an execution loop.
- It does not run overnight generation.
- It does not write runtime files.
- It does not alter Gateway behavior.
- It does not alter Docker Compose.
- It does not add shell execution features.

## Preconditions

Read these first:

- [47-prompt-variants-plan.md](47-prompt-variants-plan.md)
- [48-small-batch-image-safety.md](48-small-batch-image-safety.md)
- [50-batch-output-naming-policy.md](50-batch-output-naming-policy.md)
- [57-prompt-variant-stop-conditions.md](57-prompt-variant-stop-conditions.md)

Expected state:

- You are on PC-1.
- You understand where generated outputs are stored.
- You have a reviewed variant list.
- You know real generation remains manually guarded.
- You are ready to stop llama-server before image mode.

## Why This Is Operator-Controlled

Prompt variants are intentionally manual at this stage. The operator decides when to prepare image mode, when to run one variant, when to inspect output, and when to stop.

This protects against accidental large GPU jobs, unclear output folders, and generated files entering Git.

## Variant List

| Variant | Prompt change | Size | Steps | Seed | Purpose |
| --- | --- | --- | --- | --- | --- |
| A | Base pergola prompt, same seed | `512x512` | `4` | `1783334081` | Confirm baseline behavior |
| B | Add `wide angle photo` | `512x512` | `4` | `1783334081` | Test camera framing |
| C | Add `rainy weather` | `512x512` | `4` | `1783334081` | Test weather change |
| D | Add `evening warm light` | `512x512` | `4` | `1783334081` | Test lighting change |
| E | Add `technical construction photo` | `512x512` | `4` | `1783334081` | Test documentation-style output |

Known base prompt:

```text
realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight
```

## Fixed Settings

Keep these fixed for the first controlled session:

| Setting | Value |
| --- | --- |
| Width | `512` |
| Height | `512` |
| Steps | `4` |
| Seed | `1783334081` |
| Workflow JSON | `/home/cuneyt/MoE/runtime/media/workflows/flux-schnell-first-image.json` |

## Safety Checks Before Generation

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
make image-readiness
make media-dashboard-status
make comfyui-vram-status
```

Do not continue if readiness, dashboard status, or VRAM status is unclear.

## Prepare Image Mode

Only prepare image mode when you intentionally want real generation and have reviewed the stop conditions.

### Run on PC-1

```bash
APPLY=1 STOP_LLM=1 scripts/image/image-mode-prepare.sh
```

Expected good sign: llama-server is stopped through the guarded path and image/media readiness is checked.

## Readiness After Preparation

### Run on PC-1

```bash
make image-readiness
make comfyui-health
make comfyui-vram-status
```

Expected good sign: ComfyUI is healthy, VRAM is available, and readiness is green.

## Run One Variant At A Time

Use [55-prompt-variant-run-template.md](55-prompt-variant-run-template.md) before each variant.

For each variant:

1. Confirm the variant ID and prompt.
2. Confirm size, steps, and seed are unchanged.
3. Confirm filename prefix follows [50-batch-output-naming-policy.md](50-batch-output-naming-policy.md).
4. Run only the one reviewed variant.
5. Inspect output before moving to the next variant.

Do not use an automatic loop. Do not queue all variants at once.

## Inspect Output After Each Variant

### Run on PC-1

```bash
make image-latest
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -30
```

Record the output path, filename, file size, and result before continuing.

## Stop Conditions

Stop immediately if:

- Free VRAM is too low.
- llama-server is still running during image mode.
- ComfyUI health fails.
- Media API or Media Worker fails.
- Output path is unclear.
- No new image is detected.
- Image files appear inside the repo.
- GPU temperature is unexpectedly high.
- Generations repeatedly fail.
- You are unsure what the next command will do.

Use [57-prompt-variant-stop-conditions.md](57-prompt-variant-stop-conditions.md) for safe next steps.

## Safe Shutdown

When the session is done or stopped, return to coding mode.

### Run on PC-1

```bash
APPLY=1 START_LLM=1 scripts/image/image-safe-shutdown.sh
```

Expected good sign: image mode shuts down safely and the coding model is restored.

## Git Safety Check

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: generated media and model files do not appear as tracked or staged repo files.

## Evidence To Record

Record:

- Date/time
- Git commit
- Operator
- Readiness result
- ComfyUI status
- VRAM before first variant
- Variant count
- Per-variant output path and result
- Latest images after run
- Dashboard review result
- Safe shutdown result
- Coding model restored yes/no
- Git safety result
- Errors/blockers

Use [56-controlled-variant-evidence-template.md](56-controlled-variant-evidence-template.md).
