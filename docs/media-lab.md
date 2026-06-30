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
