# Prompt Interpreter Worker

Milestone 26.1.6 adds a rule/template based Prompt Interpreter Worker for PC-2.

## Purpose

The worker converts natural language media prompts into safe structured dry-run media job specs before Media Lab jobs are created.

It does not call a model, ComfyUI, llama-server, Media API, or any generation engine.

In Milestone 26.3, Prompt Interpreter output can be used manually as input to Media API image jobs. The interpreter still does not submit jobs or trigger generation by itself.

In Milestone 26.4, Gateway uses the Prompt Interpreter at `http://192.168.50.2:8230` when it is reachable. If it is unavailable, Gateway falls back to local deterministic classification and returns a warning. Gateway planning still returns a dry-run job spec and does not generate media by itself.

In Milestone 26.5, the Media Dashboard reports Prompt Interpreter reachability as status only. It does not start, stop, or call generation services.

## PC-2 Role

PC-2 is the helper host for:

- Prompt interpretation.
- Job metadata preparation.
- Feedback and reports.
- Future optional mini model prompt interpretation.

PC-1 remains the generation host for heavy GPU work.

## Rule-Based First Version

The first version is deterministic and keyword-based. It classifies prompts into:

- `image`
- `video`
- `3d_model`
- `rigging`
- `animation`
- `3d_suite`
- `unknown`

No model is required.

## API

Port:

```text
8230
```

Endpoints:

```text
GET  /health
POST /interpret
POST /interpret/batch
```

Example request:

```json
{
  "prompt": "gerçekçi ahşap pergola görseli üret",
  "target_mode": "auto",
  "style": "auto",
  "mode": "dry_run"
}
```

Example job spec:

```json
{
  "job_type": "image",
  "mode": "dry_run",
  "prompt": "gerçekçi ahşap pergola görseli üret",
  "workflow": "image_default",
  "metadata": {
    "width": 1024,
    "height": 1024,
    "steps": 4,
    "engine": "disabled",
    "generation_host": "pc1",
    "helper_host": "pc2",
    "source": "prompt-interpreter-worker"
  }
}
```

## Mode Mapping

- `image` maps to `image_default`.
- `video` maps to `video_default`.
- `3d_model` maps to `3d_default`.
- `rigging` maps to `rigging_default`.
- `animation` maps to `animation_default`.
- `3d_suite` maps to `3d_suite_default` with grouped 3D, rigging, and animation capabilities.

## Safety Model

- Dry-run only.
- Empty prompts are rejected.
- Prompts over 4000 characters are rejected.
- Batches over 20 items are rejected.
- `generation_enabled=false`.
- `model_enabled=false`.
- No output files are written.
- No shell commands are executed.
- No ComfyUI calls are made.
- No llama-server calls are made.
- No media generation is started.

## Optional Local Test

Default `make test` does not require Prompt Interpreter dependencies.

Use a repo-external virtualenv:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/prompt-interpreter
source ~/MoE/runtime/venvs/prompt-interpreter/bin/activate
pip install -r apps/prompt-interpreter-worker/requirements.txt
make test-prompt-interpreter-worker
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase.

## Optional PC-2 Activation

```bash
make pc2-sync-code
make pc2-prompt-interpreter-up
make pc2-prompt-interpreter-health
make pc2-prompt-interpreter-sample
```

These commands are optional and not part of default tests.

## Future Mini Model Option

Milestone 26.1.7 may add an optional small local model on PC-2 if rule/template interpretation is insufficient. Heavy generation remains on PC-1.
