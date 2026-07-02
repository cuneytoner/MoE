# Human-Approved Improvement Plan

Milestone 28.9 adds a plan-only improvement planner.

It reads the reviewed learning-loop report:

```text
/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json
```

It writes a human-reviewable patch-plan style plan under runtime:

```text
/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json
```

## Commands

```bash
make improvement-plan-local
make test-improvement-plan
```

If the learning-loop report is missing, `make improvement-plan-local` prints a clear skip message and exits successfully.

## Plan Scope

The plan includes:

- generated timestamp
- source report path
- source record count
- `plan_status=review_required`
- `apply_supported=false`
- `human_review_required=true`
- proposed changes
- validation plan
- safety boundaries
- next steps

Proposed changes are deterministic and based only on aggregate observations and recommendations from the learning-loop report. Each proposed change stays advisory and includes target files for review, not automatic edits.

## Safety

This milestone does not:

- apply changes
- train or fine-tune models
- write memory entries
- call Memory API, Gateway, or llama-server
- modify router config
- update prompt templates
- switch models
- control Docker
- start, stop, or restart services
- include raw feedback reason text
- include raw prompt text
- include raw model responses
- include individual feedback records

Every proposed change requires explicit human approval before any source, config, prompt, router, documentation, memory, Docker, service, or runtime change.

Milestone 29.0 consumes this plan to create a reviewed improvement patch plan:

```bash
make improvement-patch-plan-local
```

That patch plan is written to `/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json` and remains advisory. It does not apply patches or edit target files.

Milestone 29.1 consumes the reviewed patch plan to create a pending human approval packet:

```bash
make router-prompt-approval-local
```

That packet is written to `/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json` and keeps router, prompt, docs, tests, and model-routing candidates reviewable without applying changes.

Milestone 29.2 consumes aggregate feedback and reviewed learning artifacts to create memory candidates:

```bash
make feedback-memory-candidates-local
```

The candidate review is written to `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json` and remains human-review-only. It does not write to Memory API or store raw prompts or raw model responses.
