# Guided Image Generation

Milestone 26.6 adds a guided command pack for the image generation lifecycle.

The command pack is explicit and user-run. It does not enable real generation by default, does not start real generation without `APPLY=1`, does not start the ComfyUI external bridge without explicit image-mode preparation, and does not delete or move generated outputs.

## Safety Model

- Dry-run commands are the default.
- Real generation requires `APPLY=1`.
- Full-cycle real generation additionally requires `CONFIRM_IMAGE_FULL_CYCLE=1`.
- Media API and Media Worker must expose `real_generation_enabled=true`.
- ComfyUI bridge mode must be started explicitly.
- `llama-server` may need to be stopped for VRAM; the prepare script only stops it with `STOP_LLM=1`.
- Model files stay under `/home/cuneyt/MoE_Models_Backup`.
- Generated images stay under `/home/cuneyt/MoE/runtime/media/outputs/images`.

## Commands

Readiness:

```bash
make image-readiness
```

Dry-run:

```bash
make image-dry-run
```

Prepare image mode:

```bash
APPLY=1 STOP_LLM=1 make image-mode-prepare
```

Run real image generation through the Media API bridge:

```bash
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true make image-real-run
```

List latest outputs:

```bash
make image-latest
OPEN=1 make image-latest
```

Return to safe/coding mode:

```bash
APPLY=1 START_LLM=1 make image-safe-shutdown
```

## Dry-Run Workflow

```bash
make image-readiness
make image-dry-run
make image-latest
```

This does not start ComfyUI, enable real generation, or create an image.

## Real Workflow

```bash
APPLY=1 STOP_LLM=1 make image-mode-prepare
APPLY=1 MEDIA_REAL_GENERATION_ENABLED=true make image-real-run
make image-latest
APPLY=1 START_LLM=1 make image-safe-shutdown
```

Gateway real generation remains separately guarded. This command pack uses the Media API bridge path through `make media-image-real-run`.

## Full Cycle

Default full cycle is dry-run only:

```bash
make image-full-cycle
```

Real full cycle requires explicit confirmation:

```bash
APPLY=1 CONFIRM_IMAGE_FULL_CYCLE=1 make image-full-cycle
```

It does not automatically run safe shutdown unless requested:

```bash
APPLY=1 CONFIRM_IMAGE_FULL_CYCLE=1 AUTO_SAFE_SHUTDOWN=1 make image-full-cycle
```

## Why The Gates Exist

Gateway real generation remains guarded so planning and dry-run requests do not accidentally spend GPU time.

ComfyUI bridge mode is explicit because Docker containers need to reach host ComfyUI through `host.docker.internal:8188`.

`llama-server` may need to stop because Flux image generation can need most of the GPU VRAM.

## Output Locations

Generated images are surfaced under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

The command pack never copies outputs into the repository.

## Troubleshooting

Low VRAM:

```bash
APPLY=1 STOP_LLM=1 make image-mode-prepare
```

ComfyUI unreachable from Docker:

```bash
COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up
make image-readiness
```

Media API real generation disabled:

```bash
APPLY=1 STOP_LLM=1 make image-mode-prepare
```

Prompt Interpreter unavailable:

```bash
make pc2-prompt-interpreter-health
make gateway-media-plan
```

No new image found:

```bash
make media-latest-images
STRICT_NEW_OUTPUT=1 make comfyui-first-image-apply
```

Gateway real rejected by default:

```bash
make gateway-media-real-plan
```

Real Gateway generation needs `GATEWAY_MEDIA_REAL_ALLOWED=true` plus request-level confirmation; the guided image pack does not change that gate.

## Dashboard UI

The Dashboard UI MVP can display readiness, gates, warnings, safe command hints, and latest image paths:

```bash
make dashboard-ui-up
make dashboard-ui-open
```

It is read-only and does not run guided image commands.
