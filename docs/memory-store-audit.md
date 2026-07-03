# Memory Store Audit

Milestone 29.4 adds an audit-only duplicate review for memory store plans.

It reads:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json
```

It may also read candidate details from:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
```

It writes the audit report under runtime:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json
```

## Commands

```bash
make memory-store-audit-local
make test-memory-store-audit
```

## What It Checks

The audit groups approved, blocked, and pending memory candidates by normalized category and title.

Normalization:

- lowercase
- trim whitespace
- collapse repeated spaces
- remove simple punctuation

Duplicate groups are marked for human review with one of:

- `review_and_merge`
- `keep_separate`
- `reject_duplicates`

## Safety

This milestone is audit-only. It does not:

- write to Memory API
- call Memory API
- approve candidates
- train or fine-tune models
- modify memory
- modify router config
- modify prompt templates
- call Gateway or llama-server
- depend on PC2 availability
- include raw prompts
- include raw model responses
- include individual feedback records
- commit generated runtime reports

The audit recommendations are not applied automatically.

Milestone 29.5 adds append-only apply logging for later approved store attempts. See [memory-store-apply-log.md](memory-store-apply-log.md).

Milestone 29.6 adds a helper report that combines candidates, plan status, and audit duplicate information into a manual review aid. See [memory-candidate-approval-helper.md](memory-candidate-approval-helper.md).

Milestone 29.7 runs the helper, plan, dry-run store, apply-log status, and audit as a dry-run-only E2E flow. See [memory-approval-dry-run-e2e.md](memory-approval-dry-run-e2e.md).

Milestone 29.8 exposes audit and duplicate summaries through a read-only dashboard endpoint. See [memory-approval-dashboard.md](memory-approval-dashboard.md).

Milestone 29.9 adds a manual store runbook and `make memory-store-manual-preflight` so audit review remains part of the human-operated real write checklist. See [memory-approval-manual-store-runbook.md](memory-approval-manual-store-runbook.md).
