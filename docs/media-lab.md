# Media Lab Foundation

Milestone 25 creates the source-only foundation for future image, video, 3D, rigging, animation, and media orchestration workflows.

This milestone is dry-run only. It does not install ComfyUI, install Blender, download models, run GPU jobs, call model runtime, or generate media assets.

## Purpose

Media Lab will eventually provide queued local media generation workflows while preserving source/runtime/model separation.

Source code lives in this repository. Runtime media jobs, reports, and generated assets belong under:

```text
/home/cuneyt/MoE/runtime/media
```

Media models belong under:

```text
/home/cuneyt/MoE_Models_Backup
```

## Runtime Paths

```text
/home/cuneyt/MoE/runtime/media
/home/cuneyt/MoE/runtime/media/jobs
/home/cuneyt/MoE/runtime/media/outputs/images
/home/cuneyt/MoE/runtime/media/outputs/videos
/home/cuneyt/MoE/runtime/media/outputs/3d
/home/cuneyt/MoE/runtime/media/outputs/rigs
/home/cuneyt/MoE/runtime/media/outputs/animations
/home/cuneyt/MoE/runtime/reports/media
```

Prepare the runtime layout:

```bash
make check-media-layout
```

## Services

`apps/media-api` exposes a dry-run job API on port `8300`.

`apps/media-worker` exposes a dry-run worker API on port `8310`.

Optional Docker profile:

```bash
docker compose -f infra/docker/docker-compose.yml --profile media up -d --build media-api media-worker
```

The media services are not part of default `make test`.

## Job Schema

Job request:

```json
{
  "job_type": "image",
  "mode": "dry_run",
  "prompt": "text",
  "workflow": "default",
  "metadata": {}
}
```

Supported future job types:

- `image`
- `video`
- `3d`
- `rigging`
- `animation`

Only `mode=dry_run` is supported in Milestone 25.

## API

Health:

```bash
curl -fsS http://127.0.0.1:8300/health
```

Create a dry-run job:

```bash
curl -fsS -H "Content-Type: application/json" \
  -X POST \
  -d '{"job_type":"image","mode":"dry_run","prompt":"test","workflow":"default","metadata":{}}' \
  http://127.0.0.1:8300/media/jobs
```

Process a job in dry-run mode:

```bash
curl -fsS -X POST http://127.0.0.1:8300/media/jobs/JOB_ID/dry-run-process
```

## Safety Model

- Dry-run only.
- No real image generation.
- No real video generation.
- No real 3D generation.
- No rigging or animation execution.
- No ComfyUI calls.
- No Blender calls.
- No model runtime calls.
- No arbitrary shell execution.
- No model downloads.
- No generated media in the codebase.

## Config Examples

Placeholder model config:

```text
configs/media-models.example.yaml
```

Dry-run workflow config:

```text
configs/media-workflows.example.yaml
```

These are examples only. They do not enable generation.

## Optional Local Test

Default `make test` does not require Media API dependencies.

Use a repo-external virtualenv for optional local Media API tests:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/media-api
source ~/MoE/runtime/venvs/media-api/bin/activate
pip install -r apps/media-api/requirements.txt
make test-media-api
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase.

## Future Milestones

- Milestone 26: Image Generation Service
- Milestone 27: Video Generation Service
- Milestone 28: 3D Model Generation Pipeline
- Milestone 29: Rigging Pipeline
- Milestone 30: Animation Pipeline
- Milestone 31: Media Workflow Orchestrator

## Image Generation Preparation

Milestone 26.0 extends the dry-run Media Lab foundation with image-specific metadata validation and reports.

It adds placeholders for Flux Schnell and SDXL, but does not download or require image models. Use:

```bash
make check-image-models
```

Image dry-run jobs can include width, height, steps, seed, engine, and model id metadata. Reports include prompt length, requested size, workflow, engine, model id, and explicit `generation_performed=false`.

Real image generation remains disabled until a later explicit milestone.

## Image Engine Decision Prep

Milestone 26.1-pre recommends ComfyUI as the primary future image engine while keeping generation disabled. ComfyUI is preferred for workflow orchestration, Flux support, future video workflows, image-to-video bridging, node workflow exportability, and debugging. Diffusers remains a deferred alternative for simpler direct Python generation.

Optional planning commands:

```bash
make check-comfyui-layout
make plan-image-model-downloads
```

These commands do not install ComfyUI, download models, create symlinks, run GPU jobs, or generate media. Runtime engine files belong under `/home/cuneyt/MoE/runtime/media-engines/comfyui`; model files remain under `/home/cuneyt/MoE_Models_Backup`.

## ComfyUI Runtime Activation Plan

Milestone 26.1 adds optional, user-run ComfyUI runtime commands. They are not part of default `make test` and do not run image generation.

```bash
make install-comfyui-runtime
make check-comfyui-runtime
make plan-flux-schnell-models
make link-comfyui-models-dry-run
make comfyui-up
make comfyui-health
make comfyui-down
```

The runtime install target writes only under `/home/cuneyt/MoE/runtime/media-engines/comfyui`. Model files stay under `/home/cuneyt/MoE_Models_Backup` and are exposed to ComfyUI by symlink only. Real generation remains disabled until Milestone 26.2.

## Runtime Mode Separation

Milestone 26.1.5 adds Control Plane runtime modes before real generation:

- `coding`: excludes image, video, and 3D generation workers so coding and chat resources stay predictable.
- `image`: focuses on image generation services and recommends stopping `llama-server` for VRAM.
- `video`: focuses on future video generation and stops image/3D workers.
- `3d_suite`: groups 3D model generation, rigging, and animation as one future mode.
- `media_off`: stops planned media workers.

Mode plans are dry-run by default and do not start generation.

## Prompt Interpretation

Milestone 26.1.6 adds a PC-2 Prompt Interpreter Worker before real media jobs. It accepts natural language prompts, classifies the intended media workflow, and returns a structured dry-run job spec.

The interpreter does not call Media API by default. It is a safe preparation layer between user intent and future queued media jobs.

## First Real Image Generation

Milestone 26.2 adds a guarded first-image path through ComfyUI and Flux Schnell. Downloads, model linking, smoke checks, and workflow submission are all explicit user-run commands. Default tests do not download models, start ComfyUI, or run GPU jobs.

Generated images must stay under `/home/cuneyt/MoE/runtime/media/outputs/images`. PC-2 remains a helper host and does not run generation.

## Media Image Bridge

Milestone 26.3 connects Media API, Media Worker, and ComfyUI in a gated bridge:

- Media API creates image jobs under `/home/cuneyt/MoE/runtime/media/jobs`.
- Dry-run jobs are always allowed.
- Real image jobs are rejected unless `MEDIA_REAL_GENERATION_ENABLED=true`.
- Media API delegates real processing to Media Worker.
- Media Worker submits Flux Schnell workflows to ComfyUI on PC-1.
- Outputs are copied into `/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>/`.

PC-2 Prompt Interpreter can prepare structured job specs upstream, but M26.3 still uses a manual bridge. Gateway does not trigger generation.

Docker networking for the media bridge:

- Media API calls Media Worker at `http://media-worker:8310` inside the Docker network.
- Media Worker calls host ComfyUI at `http://host.docker.internal:8188`.
- Linux Docker uses `extra_hosts: host.docker.internal:host-gateway` for the media services.

## Gateway Media Adapter

Milestone 26.4 adds guarded Gateway media endpoints:

```text
GET  /gateway/media/health
POST /gateway/media/plan
POST /gateway/media/jobs/dry-run
POST /gateway/media/jobs/real
GET  /gateway/media/jobs/{job_id}
```

Gateway planning accepts a natural language prompt and returns a dry-run plan. It uses the PC-2 Prompt Interpreter at `http://192.168.50.2:8230` when reachable and falls back to local deterministic classification when it is not reachable.

Dry-run job creation calls Media API and remains the default safe path:

```bash
make gateway-media-plan
make gateway-media-dry-run
```

Real generation is rejected by default:

```bash
make gateway-media-real-plan
```

Real job creation requires all gates:

- `GATEWAY_MEDIA_REAL_ALLOWED=true` on Gateway.
- `MEDIA_REAL_GENERATION_ENABLED=true` on Media API and Media Worker.
- `confirm_real_generation=true` in the request.
- `target_mode=image`.

Gateway does not start services, stop services, control PC-2, start ComfyUI, stop ComfyUI, control Docker containers, execute shell commands, or write generated media into the repository.
