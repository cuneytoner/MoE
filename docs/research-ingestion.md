# Research Ingestion Worker

Milestone 24.1 adds the first Research Ingestion Worker skeleton. It is source-approved, read-only, and report-first.

## Purpose

The Research Ingestion Worker prepares a safe path for turning approved project and research sources into reviewable reports. The first version processes only local markdown and text files from an approved source config.

It does not crawl the web, fetch arbitrary URLs, modify source files, apply patches, execute shell commands, control Docker, or switch model runtime.

## Safety Model

- Approved sources only.
- No unrestricted web crawling.
- No remote fetch in Milestone 24.1.
- No source modification.
- No automatic code edits.
- No patch application.
- No shell execution from the worker.
- No Docker or model runtime control.
- Human review before any recommendation becomes code or config.

Remote URL sources may appear in the source config as placeholders, but the worker skips them with `remote fetch not implemented`.

## Approved Sources

Approved sources live in:

```text
configs/research-sources.example.yaml
```

Supported source types in Milestone 24.1:

- `local_markdown`
- `local_text`

Unsupported or disabled sources are skipped. Paths must stay inside `RESEARCH_SOURCE_ROOT`, and hidden, runtime, model, data, checkpoint, cache, virtualenv, and `custom_nodes` directories are rejected.

## Runtime Storage

Research reports belong under:

```text
/home/cuneyt/MoE/runtime/reports/research
```

Do not write reports, caches, raw fetched content, virtualenvs, or generated outputs into the codebase.

## API

Health:

```bash
curl -fsS http://127.0.0.1:8210/health
```

Dry run:

```bash
curl -fsS -H "Content-Type: application/json" \
  -X POST \
  -d '{"mode":"dry_run","source_set":"default","store_findings":false}' \
  http://127.0.0.1:8210/research/run
```

Latest report:

```bash
curl -fsS http://127.0.0.1:8210/research/latest
```

Only `dry_run` mode is supported. `store_findings=false` is the default and does not call Memory API.

## Optional Local Test

Default `make test` does not require Research Ingestion Worker dependencies.

Use a repo-external virtualenv for optional local worker tests:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/research-ingestion
source ~/MoE/runtime/venvs/research-ingestion/bin/activate
pip install -r apps/research-ingestion-worker/requirements.txt
make test-research-ingestion
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase.

## PC-2 Activation

Research ingestion is optional on PC-2 and runs through the `research` compose profile only when explicitly started.

From PC-1:

```bash
make pc2-sync-code
make pc2-research-up
make pc2-research-health
make pc2-research-dry-run
ssh cuneyt@192.168.50.2 'ls -lah /home/cuneyt/MoE/runtime/reports/research'
```

Stop only the research worker:

```bash
make pc2-research-down
```

The PC-2 worker references PC-1 services through:

- Gateway: `http://192.168.50.1:8100`
- Memory API: `http://192.168.50.1:8101`

## Future Remote Source Gate

Remote source ingestion must be a future approval-gated milestone. Before enabling it, define source allowlists, fetch limits, caching rules, provenance fields, retry behavior, robots/publisher considerations, and review workflow.
