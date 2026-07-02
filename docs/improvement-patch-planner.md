# Reviewed Improvement Patch Planner

Milestone 29.0 adds a patch-plan-only planner.

It reads the human-approved improvement plan:

```text
/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json
```

It writes a reviewed patch plan under runtime:

```text
/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json
```

## Commands

```bash
make improvement-patch-plan-local
make test-improvement-patch-plan
```

If the human-approved improvement plan is missing, `make improvement-patch-plan-local` prints a clear skip message and exits successfully.

## Patch Plan Scope

The patch plan includes:

- generated timestamp
- source plan path and status
- `patch_plan_status=review_required`
- `apply_supported=false`
- `human_review_required=true`
- patch groups
- validation plan
- safety boundaries
- review checklist
- next steps

Each patch group includes target files, a proposed patch strategy, expected validation, risk, and human approval flags. It does not include an auto-apply diff.

## Safety

This milestone does not:

- apply patches
- edit files automatically
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
- commit generated runtime reports

Any future implementation must be separately approved and reviewed through Git diffs.

## Approval Packet

Milestone 29.1 consumes the reviewed patch plan to create a pending human approval packet:

```bash
make router-prompt-approval-local
make test-router-prompt-approval
```

The packet is written to `/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json`. It separates allowed router, prompt, docs, tests, and model-routing candidates from blocked memory, ops, unknown, and high-risk items. It remains advisory and does not apply patches or edit target files.
