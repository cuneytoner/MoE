# Human-Approved Memory Store Workflow

Milestone 29.3 adds a human-approved workflow for storing reviewed memory candidates.

It reads the memory candidate review:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
```

It writes a store plan under runtime:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json
```

Optional approval file:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

Approval file shape:

```json
{
  "approved_candidate_ids": ["memory-candidate-001"]
}
```

## Commands

Generate or refresh the plan:

```bash
make memory-store-plan-local
```

Dry-run the approved store workflow:

```bash
make memory-store-approved
```

Actually call Memory API only after explicit approval:

```bash
APPLY=1 make memory-store-approved
```

The Memory API URL defaults to:

```text
http://127.0.0.1:8101
```

Override only the API endpoint when needed:

```bash
MEMORY_API_URL=http://127.0.0.1:8101 make memory-store-approved
```

## Safety

Default mode is dry-run. Plan generation never writes to Memory API.

Memory writes require all of these:

- a human-created `approved-memory-candidates.json`
- a regenerated `memory-store-plan.json`
- explicit `APPLY=1`
- reachable Memory API

The workflow stores only sanitized `proposed_memory_text` from approved candidates. It does not store raw prompts, raw model responses, raw feedback reason bodies, individual feedback records, secrets, credentials, or sensitive data.

The workflow does not train or fine-tune models, modify router config, modify prompt templates, modify model mappings, switch models, control Docker, or start/stop services.

## Test

```bash
make test-memory-store-workflow
```

The test verifies dry-run behavior without requiring Memory API to be reachable and confirms no generated plan is written inside the repository.

## Audit

Milestone 29.4 audits the generated memory store plan for duplicate candidate groups:

```bash
make memory-store-audit-local
make test-memory-store-audit
```

The audit is written to `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json`. It is review-only and does not approve candidates or write to Memory API.
