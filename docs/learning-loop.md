# Reviewed Learning Loop Report

Milestone 28.8 adds a reviewed learning loop report generator.

It reads the aggregate feedback summary:

```text
/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json
```

It writes a human-reviewable report under runtime:

```text
/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json
```

## Commands

```bash
make learning-loop-report-local
make test-learning-loop-report
```

If the feedback summary is missing, `make learning-loop-report-local` prints a clear skip message and exits successfully.

## Report Scope

The report includes aggregate-only fields:

- generated timestamp
- source summary path
- source record count
- rating counts
- source counts
- router intent counts
- model counts
- top tags
- observations
- recommendations
- `apply_supported=false`
- `human_review_required=true`

Recommendations are deterministic and based only on aggregate counts. They may suggest human review of prompts, router examples, docs, tests, memory documentation, Gateway behavior, or routing alignment.

## Safety

This milestone does not:

- train or fine-tune models
- write memory entries
- call Memory API, Gateway, or llama-server
- modify router config
- update prompt templates
- switch models
- control Docker
- start, stop, or restart services
- include raw prompt text
- include raw model responses
- include individual feedback records

The report is advisory. Any follow-up learning loop must be reviewed and implemented explicitly in a later milestone.

Milestone 28.9 consumes this report to create a human-approved improvement plan:

```bash
make improvement-plan-local
```

That plan is written to `/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json` and remains patch-plan style guidance only.

Milestone 29.0 turns the human-approved improvement plan into a reviewed patch plan:

```bash
make improvement-patch-plan-local
```

Milestone 29.1 turns that reviewed patch plan into a pending human approval packet for router, prompt, docs, tests, and model-routing candidates:

```bash
make router-prompt-approval-local
```

The approval packet is written to `/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json`. It remains advisory, sets `apply_supported=false`, and does not edit files or mutate runtime state.

Milestone 29.2 converts aggregate reports into human-reviewable memory candidates:

```bash
make feedback-memory-candidates-local
```

The candidate review is written to `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`. It does not write to Memory API, call Memory API, train models, mutate memory, or include raw prompts, raw model responses, or individual feedback records.

Milestone 29.3 turns reviewed candidates into a human-approved memory store plan:

```bash
make memory-store-plan-local
make memory-store-approved
```

The plan is written to `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`. It is dry-run by default and requires `APPLY=1` before any Memory API write.
