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
