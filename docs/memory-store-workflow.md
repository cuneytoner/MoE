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

## Apply Log

Milestone 29.5 adds append-only runtime logging around approved store attempts:

```bash
make memory-store-apply-log-status
LOG_DRY_RUN=1 make memory-store-approved
```

Dry-runs do not log unless `LOG_DRY_RUN=1`. Real Memory API writes still require `APPLY=1`. See [memory-store-apply-log.md](memory-store-apply-log.md).

## Approval Helper

Milestone 29.6 adds a helper report and example approval file for manual review:

```bash
make memory-candidate-approval-helper-local
make memory-candidate-list-local
```

The helper does not create the real `approved-memory-candidates.json`, does not approve candidates automatically, and does not call Memory API. See [memory-candidate-approval-helper.md](memory-candidate-approval-helper.md).

## Dry-Run E2E

Milestone 29.7 adds a dry-run-only end-to-end check for candidate review, helper output, plan generation, store dry-run, apply-log status, and audit:

```bash
make memory-approval-dry-run-e2e-local
USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local
make memory-approval-dry-run-e2e-status
```

It never runs `APPLY=1`, never writes to Memory API, and removes its test approval fixture by default. See [memory-approval-dry-run-e2e.md](memory-approval-dry-run-e2e.md).

## Dashboard

Milestone 29.8 adds a read-only dashboard view for the approval workflow:

```text
GET /gateway/memory-approval/dashboard
```

The view reads runtime reports only and provides compact summaries without approval, apply, store, or script execution controls. See [memory-approval-dashboard.md](memory-approval-dashboard.md).

## Manual Store Runbook

Milestone 29.9 adds a manual store runbook and preflight for the human-operated real write path:

```bash
make memory-store-manual-preflight
make test-memory-store-manual-preflight
```

Real writes remain manual only with `APPLY=1 make memory-store-approved`, and tests never run `APPLY=1`. See [memory-approval-manual-store-runbook.md](memory-approval-manual-store-runbook.md).

Milestone 29.10 adds `make memory-store-real-apply-guardrail`, a read-only review that runs before any `APPLY=1` write. It rejects test fixtures and raw prompt/response markers before Memory API writes; batch apply with more than one approved candidate prints a warning unless `ALLOW_BATCH_MEMORY_APPLY=1` is set, which silences only that warning and never bypasses FAIL checks.
