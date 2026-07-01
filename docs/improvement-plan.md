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
