# Feedback / Success Memory

Milestone 24.2 adds a transparent feedback layer for task outcomes. It stores structured events in runtime JSONL files first, then produces reviewable reports.

## Purpose

Feedback / Success Memory records how work actually went:

- task id
- task type
- user goal
- route intent
- model target
- actual model used
- tools used or planned
- selected files
- tests run
- outcome status
- failure reason
- notes
- timestamp

The goal is to make future routing, prompts, and planning easier to review. It does not change router config, model mappings, prompts, or source files automatically.

## Runtime Storage

Milestone 24.2 uses runtime-only JSONL storage:

```text
/home/cuneyt/MoE/runtime/feedback/events.jsonl
```

Reports belong under:

```text
/home/cuneyt/MoE/runtime/reports/feedback
```

Do not store feedback data in the source repository. Do not add PostgreSQL schema changes in this milestone.

## Event Schema

Example event:

```json
{
  "task_type": "coding",
  "goal": "Add feedback worker",
  "route_intent": "code",
  "model_target": "qwen-coder-14b-fast",
  "actual_model": "qwen-coder-14b-fast",
  "tools": ["code_context", "code_patch_plan"],
  "selected_files": ["docs/feedback-success-memory.md"],
  "tests_run": ["make test"],
  "outcome": "success",
  "failure_reason": "",
  "notes": "Runtime-only JSONL storage"
}
```

Allowed task types:

- `coding`
- `ops`
- `research`
- `nightly`
- `media`
- `unknown`

Allowed outcomes:

- `success`
- `failure`
- `partial`
- `unknown`

## API

Health:

```bash
curl -fsS http://127.0.0.1:8220/health
```

Store an event:

```bash
curl -fsS -H "Content-Type: application/json" \
  -X POST \
  -d '{"task_type":"coding","goal":"sample","outcome":"success","tests_run":["make test"]}' \
  http://127.0.0.1:8220/feedback/event
```

List events, oldest to newest:

```bash
curl -fsS 'http://127.0.0.1:8220/feedback/events?limit=20'
```

Generate a dry-run report:

```bash
curl -fsS -H "Content-Type: application/json" \
  -X POST \
  -d '{"mode":"dry_run","limit":100,"store_lessons":false}' \
  http://127.0.0.1:8220/feedback/report
```

Latest report:

```bash
curl -fsS http://127.0.0.1:8220/feedback/latest-report
```

## Report Generation

Feedback reports summarize:

- total event count
- success, failure, partial, and unknown counts
- counts by task type
- counts by route intent
- counts by model target
- common failure reasons

Reports are advisory. They do not modify source files, router configs, model mappings, prompts, Docker, PC-2, or model runtime.

## Memory API

`store_lessons=false` is the default. When `store_lessons=true`, the worker may store a short report summary through Memory API if it is configured and reachable.

Memory storage is optional. The worker must continue to function without Memory API.

## Safety Model

- Runtime-only writes.
- No source modification.
- No automatic router or model mapping changes.
- No patch application.
- No shell execution.
- No Docker or model runtime control.
- No Gateway control over PC-2.
- Human review before any feedback changes prompts, routing, configs, or code.

## Optional Local Test

Default `make test` does not require Feedback Worker dependencies.

Use a repo-external virtualenv for optional local worker tests:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/feedback-worker
source ~/MoE/runtime/venvs/feedback-worker/bin/activate
pip install -r apps/feedback-worker/requirements.txt
make test-feedback-worker
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase.

## PC-2 Activation

Feedback Worker is optional on PC-2 and runs through the `feedback` compose profile only when explicitly started.

From PC-1:

```bash
make pc2-sync-code
make pc2-feedback-up
make pc2-feedback-health
make pc2-feedback-sample
ssh cuneyt@192.168.50.2 'ls -lah /home/cuneyt/MoE/runtime/feedback /home/cuneyt/MoE/runtime/reports/feedback'
```

Stop only the feedback worker:

```bash
make pc2-feedback-down
```

## Future Integration

Future milestones may move feedback into PostgreSQL or a dedicated Memory API schema. That migration should preserve transparent event review and must not automatically rewrite routing, prompt, config, or model mappings.
