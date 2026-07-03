# Memory Store Apply Log

Milestone 29.5 adds append-only runtime audit logging around approved memory store attempts.

Apply log path:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl
```

Latest summary path:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json
```

## Commands

Dry-run approved memory storage:

```bash
make memory-store-approved
```

Dry-run with audit log entries:

```bash
LOG_DRY_RUN=1 make memory-store-approved
```

Show apply-log status:

```bash
make memory-store-apply-log-status
```

Actually call Memory API only after explicit approval:

```bash
APPLY=1 make memory-store-approved
```

## Logging Behavior

Dry-run mode does not write apply-log entries unless `LOG_DRY_RUN=1` is explicitly set.

`APPLY=1` appends one JSONL entry per approved candidate store attempt. Entries include candidate id, title, category, result, optional HTTP status, optional Memory API id, and safe error summaries.

Logs do not include:

- raw prompts
- raw model responses
- full API response bodies
- `proposed_memory_text`
- blocked or pending candidates

## Safety

Tests never run `APPLY=1`.

Memory API writes still require:

- human-approved candidates in the memory store plan
- explicit `APPLY=1`
- a reachable Memory API

The apply log is runtime data and must not be committed.

Milestone 29.6 adds a manual approval helper before this apply-log step. It prepares a helper report and example approval file, but does not create the real approval file or call Memory API. See [memory-candidate-approval-helper.md](memory-candidate-approval-helper.md).

Milestone 29.7 uses `LOG_DRY_RUN=1` inside a dry-run-only E2E validation flow and writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json`. See [memory-approval-dry-run-e2e.md](memory-approval-dry-run-e2e.md).

Milestone 29.8 shows apply-log counts and latest attempt time in a read-only dashboard view. See [memory-approval-dashboard.md](memory-approval-dashboard.md).

Milestone 29.9 adds a manual store runbook and `make memory-store-manual-preflight` for checking apply-log readiness before any human-run `APPLY=1 make memory-store-approved`. Tests never run `APPLY=1`. See [memory-approval-manual-store-runbook.md](memory-approval-manual-store-runbook.md).
