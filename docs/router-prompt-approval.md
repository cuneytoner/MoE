# Router And Prompt Approval Packet

Milestone 29.1 adds a human approval packet generator for router, prompt, docs, tests, and model-routing update candidates.

It reads the reviewed improvement patch plan:

```text
/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json
```

It writes an approval packet under runtime:

```text
/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json
```

## Commands

```bash
make router-prompt-approval-local
make test-router-prompt-approval
```

If the reviewed patch plan is missing, `make router-prompt-approval-local` prints a clear skip message and exits successfully.

## Approval Scope

Approval items can include only these categories:

- router
- prompt
- docs
- tests
- model-routing

Memory, ops, unknown, and high-risk items are blocked into `blocked_items` for a separate review flow.

## Safety

This milestone does not:

- apply patches
- edit target files automatically
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

The packet prepares approval-ready summaries only. Any manual edit must happen in a separate explicitly approved implementation task and be reviewed through Git diffs.
