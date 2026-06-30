# Nightly Learning Worker

Nightly learning begins at Milestone 24 as a read-only, report-first worker skeleton.

Milestone 23.5 prepares PC-2 as the preferred background worker node before Nightly Learning begins. PC-2 can host scheduled learning jobs, research ingestion, report generation, and supporting storage services while PC-1 remains the interactive coding and model runtime node.

PC-2 preparation is source-only until activation is explicitly requested. The recommended PC-2 source checkout path is `/home/cuneyt/MoE/codebase`, and runtime outputs remain under `/home/cuneyt/MoE/runtime`. The optional PC-2 checks inspect connectivity and layout only; they do not create directories, start Docker, or deploy services.

The goal is to help the local AI stack learn from project activity without giving it authority to modify code, run shell commands, restart services, or change runtime state beyond approved report and memory writes.

## Safety Model

- No automatic code changes.
- No automatic shell command execution.
- No Docker stop/start/restart actions.
- No model runtime stop/start/switch actions.
- No automatic edits to Gateway, Memory API, Embed Worker, configs, or docs.
- No heavy LLM inference on PC-2 by default.
- Human review is required before any recommendation becomes a code or config change.

Allowed outputs:

- Nightly reports under `/home/cuneyt/MoE/runtime/reports/nightly`.
- Useful lessons stored through Memory API.
- Human-readable recommendations for future prompts, routing, tests, and docs.

## Milestone 24: Nightly Learning Worker

Preferred host: PC-2 after Milestone 23.5 validation and explicit activation.

Current implementation:

- App path: `apps/nightly-learning-worker`.
- FastAPI port: `8200`.
- Endpoints: `GET /health`, `POST /nightly/run`, and `GET /nightly/latest`.
- Supported run mode: `dry_run` only.
- Report path: `/home/cuneyt/MoE/runtime/reports/nightly`.
- Default source root inside Docker: `/workspace`, mounted read-only.
- Default lesson storage: disabled with `store_lessons=false`.

Current inputs:

- Bounded source metadata from the configured read-only source root.
- Optional Gateway health probe.
- Optional Memory API health probe.

Current outputs:

- JSON nightly report under the configured runtime reports directory.
- Optional distilled lesson sent to Memory API only when `store_lessons=true` and Memory API is reachable.

The worker must not modify source files, apply patches, execute shell commands, restart Docker, control PC-2, or switch model runtime. It should produce artifacts that can be reviewed manually before any action is taken.

Example local dry-run request when the worker is already running:

```bash
curl -fsS -H "Content-Type: application/json" \
  -X POST \
  -d '{"mode":"dry_run","include_git_status":true,"include_gateway_summary":true,"include_memory_summary":true,"store_lessons":false}' \
  http://127.0.0.1:8200/nightly/run
```

Local source-only test:

```bash
make test-nightly-learning
```

Default `make test` does not require Nightly Learning Worker Python dependencies. The worker test is optional because it uses FastAPI TestClient and needs the worker app requirements in the active Python environment.

Use a repo-external virtualenv for optional local worker tests:

```bash
mkdir -p ~/MoE/runtime/venvs
python3 -m venv ~/MoE/runtime/venvs/nightly-learning
source ~/MoE/runtime/venvs/nightly-learning/bin/activate
pip install -r apps/nightly-learning-worker/requirements.txt
make test-nightly-learning
```

Do not create `.venv`, `venv`, or any virtualenv inside the codebase. Runtime-local development environments belong under `~/MoE/runtime/venvs`.

The same setup recipe is available from:

```bash
make nightly-learning-test-env-help
```

## PC-2 Activation

Milestone 24.0.1 prepares explicit PC-2 activation for the Nightly Learning Worker. Activation is manual and command-driven from PC-1; default `make test` does not run PC-2 checks, sync code, start Docker, or require the worker to be reachable.

PC-2 paths:

- Source checkout: `/home/cuneyt/MoE/codebase`
- Runtime root: `/home/cuneyt/MoE/runtime`
- Nightly reports: `/home/cuneyt/MoE/runtime/reports/nightly`

PC-1 service URLs used by PC-2:

- Gateway: `http://192.168.50.1:8100`
- Memory API: `http://192.168.50.1:8101`

Activation flow from PC-1:

```bash
make pc2-check-connectivity
make pc2-check-layout
make pc2-sync-code
make pc2-nightly-up
make pc2-nightly-health
make pc2-nightly-dry-run
ssh cuneyt@192.168.50.2 'ls -lah /home/cuneyt/MoE/runtime/reports/nightly'
```

The first PC-2 run should be a dry run. The dry-run payload keeps `store_lessons=false`, so the worker writes only a report under the PC-2 runtime reports directory and does not attempt to store distilled lessons in Memory API by default.

## Relationship To Research Ingestion

Research ingestion is separate from Nightly Learning. The Research Ingestion Worker reads only approved local markdown/text sources in Milestone 24.1, writes research reports under `/home/cuneyt/MoE/runtime/reports/research`, and does not fetch remote URLs.

Future Nightly Learning reports may refer to reviewed research ingestion outputs, but the two workers remain separately activated and separately testable.

## Relationship To Feedback Memory

Feedback events are another future input for Nightly Learning reports. The Feedback Worker stores task outcome events under `/home/cuneyt/MoE/runtime/feedback/events.jsonl` and generates reports under `/home/cuneyt/MoE/runtime/reports/feedback`.

Nightly Learning may later summarize reviewed feedback reports, but it must not automatically change router rules, prompt templates, model mappings, source files, or runtime controls.

## Milestone 24.1: Research Ingestion Worker

Research ingestion is optional and source-approved.

Planned behavior:

- Ingest only user-approved sources.
- Summarize findings.
- Store useful findings in Memory API.
- Keep raw outputs, summaries, and logs under runtime data.
- Make no automatic code changes.

## Milestone 24.2: Feedback / Success Memory

Feedback memory records how work actually went.

Candidate fields:

- Task or milestone id.
- Router intent.
- Selected model target.
- Actual model used.
- Memory enabled or disabled.
- Tests run.
- Final status.
- Follow-up notes.

This history should improve future routing and prompts while staying transparent and inspectable.

## Milestone 24.3: Prompt & Routing Improvement Reports

The system may recommend improvements, but it must not apply them automatically.

Report topics:

- Router keyword gaps.
- Model mapping improvements.
- Prompt template improvements.
- Test coverage gaps.
- Documentation gaps.

All recommendations require human approval before code or config changes.

## Runtime Storage

Nightly learning reports belong under:

```text
/home/cuneyt/MoE/runtime/reports/nightly
```

Do not write reports, research outputs, caches, or generated memories into the source repository.
