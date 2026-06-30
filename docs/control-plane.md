# Control Plane

Milestone 26.1.5 adds a source-only Control Plane Dashboard and Runtime Mode Manager foundation before real media generation begins.

## Purpose

The Control Plane defines safe runtime modes for PC-1 and PC-2 without turning the Gateway into a system control surface. It exposes read-only status, mode definitions, and dry-run mode plans.

Control API runs on port `8400`.

## Why Before M26.2

Real image generation needs explicit mode gates so coding, image, video, and 3D workloads do not compete for GPU resources accidentally.

Milestone 26.1.5 is plan-first:

- No automatic generation.
- No automatic model downloads.
- No arbitrary shell execution.
- No automatic self-modification.
- No Gateway control of PC-2.
- No broad start/stop control.

## Runtime Modes

Mode definitions live in:

```text
configs/runtime-modes.example.yaml
```

Modes:

- `coding`: Gateway, Memory API, Embed Worker, and llama-server are the active focus. Media workers should be stopped.
- `image`: ComfyUI and Media Lab are the active focus. `llama-server` is recommended to stop for VRAM. PC-1 is the generation host.
- `video`: future video generation mode. Image/3D workers should be stopped.
- `3d_suite`: future grouped 3D model, rigging, and animation mode.
- `media_off`: media generation workers should be stopped.

`prompt-interpreter-worker` is enabled in `image`, `video`, and `3d_suite` mode plans. It is disabled in `coding` and `media_off`.

M26.2 first image generation should use the `image` mode plan before running ComfyUI Flux smoke or first-image commands.

Inspect mode plans:

```bash
make runtime-mode-coding-plan
make runtime-mode-image-plan
make runtime-mode-video-plan
make runtime-mode-3d-suite-plan
make runtime-mode-media-off-plan
```

## PC-1 Role

PC-1 is the `generation_host`.

Responsibilities:

- Heavy GPU jobs.
- `llama-server`.
- ComfyUI.
- Future video engine.
- Future Blender/3D engine.

## PC-2 Role

PC-2 is the `helper_host`.

Responsibilities:

- Prompt interpreter placeholder.
- Job queue and metadata.
- Feedback and reports.
- Future optional mini model interpreter.

## Prompt Interpreter Worker

The service name is:

```text
prompt-interpreter-worker
```

Milestone 26.1.6 implements the first rule/template-based worker on PC-2. It produces dry-run media job specs and does not call a model or generation engine.

Future milestones:

- M26.1.7: Optional Mini Model Prompt Interpreter on PC-2, small local model only if needed, structured job spec output.

## Control API

Endpoints:

```text
GET  /health
GET  /control/status
GET  /control/modes
POST /control/mode/plan
POST /control/mode/apply
```

`/control/status` is read-only. It may call known localhost health endpoints and inspect known PID files under `/home/cuneyt/MoE/runtime`.

`/control/mode/plan` is dry-run only and returns planned start/stop lists, host roles, prompt interpreter state, and VRAM recommendations.

`/control/mode/apply` is rejected by default unless future gated work explicitly enables a safe allowlist.

## Safety Model

Allowed:

- Read known localhost health endpoints.
- Inspect known runtime PID files.
- Return configured mode plans.
- Report PC-1 and PC-2 roles.

Not allowed:

- Arbitrary shell commands.
- API caller-supplied command strings.
- Automatic model downloads.
- Automatic media generation.
- Source modification.
- Runtime config modification.
- Gateway control of PC-2.

M26.3 image mode should include Media API, Media Worker, ComfyUI, and Prompt Interpreter in the planned service set. Coding mode should keep generation disabled. The Media API bridge still requires explicit `MEDIA_REAL_GENERATION_ENABLED=true`; image mode alone is not an approval to generate.

## Service Allowlist

Known services:

- `llama-server`
- `gateway-api`
- `memory-api`
- `embed-worker`
- `postgres`
- `qdrant`
- `comfyui`
- `media-api`
- `media-worker`
- `nightly-learning-worker`
- `research-ingestion-worker`
- `feedback-worker`
- `image-worker`
- `video-worker`
- `3d-worker`
- `rigging-worker`
- `animation-worker`
- `prompt-interpreter-worker`

## Future Dashboard UI

The dashboard UI should show:

- Current runtime mode.
- PC-1 and PC-2 responsibilities.
- Service health.
- Planned start/stop actions.
- VRAM warnings.
- Apply availability and safety gate state.

M26.1.5 adds API and docs only; a richer UI remains future work.

## Optional Local Test

Default `make test` does not require Control API dependencies.

Use a repo-external virtualenv:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/control-api
source ~/MoE/runtime/venvs/control-api/bin/activate
pip install -r apps/control-api/requirements.txt
make control-api-test
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase.
