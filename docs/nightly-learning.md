# Nightly Learning Roadmap

Nightly learning begins after Milestone 24. It is read-only and report-first.

Milestone 23.5 prepares PC-2 as the preferred background worker node before Nightly Learning begins. PC-2 can host scheduled learning jobs, research ingestion, report generation, and supporting storage services while PC-1 remains the interactive coding and model runtime node.

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

Planned inputs:

- Recent git activity.
- Test results and test gaps.
- Gateway route decisions.
- Memory API records.
- Runtime and model health reports.

Planned outputs:

- Nightly summary report.
- Task success/failure observations.
- Suggested follow-up tasks.
- Useful lessons stored in Memory API.

The worker should be scheduled and observable. It should produce artifacts that can be reviewed manually before any action is taken.

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
