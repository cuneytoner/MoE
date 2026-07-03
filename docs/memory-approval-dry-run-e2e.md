# Memory Approval Dry-Run E2E

Milestone 29.7 adds an end-to-end dry-run workflow for the memory approval path.

Runtime E2E report path:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json
```

## Commands

Run the dry-run flow without an approval fixture:

```bash
make memory-approval-dry-run-e2e-local
```

Run the dry-run flow with a temporary test approval fixture:

```bash
USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local
```

Show status:

```bash
make memory-approval-dry-run-e2e-status
```

Run tests:

```bash
make test-memory-approval-dry-run-e2e
```

## Flow

The script orchestrates existing safe local targets:

- `make memory-candidate-approval-helper-local`
- `make memory-candidate-list-local`
- `make memory-store-plan-local`
- `LOG_DRY_RUN=1 make memory-store-approved`
- `make memory-store-apply-log-status`
- `make memory-store-audit-local`

It never runs `APPLY=1`.

## Test Approval Fixture

`USE_TEST_APPROVAL_FIXTURE=1` creates a temporary dry-run-only approval file at:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

The fixture contains:

- `test_fixture: true`
- `dry_run_only: true`

The fixture is removed at the end unless `KEEP_TEST_APPROVAL_FIXTURE=1` is set.

If a non-test real approval file already exists, the script refuses to overwrite it.

## Safety

This workflow does not:

- write to Memory API
- approve candidates automatically
- keep a permanent approval fixture by default
- store raw prompts
- store raw model responses
- include individual feedback records
- switch models
- control Docker
- train or fine-tune models
- commit generated runtime reports

Milestone 29.8 exposes the E2E status through a read-only dashboard endpoint. See [memory-approval-dashboard.md](memory-approval-dashboard.md).

Milestone 29.9 adds a manual store runbook and `make memory-store-manual-preflight` for the human-operated real write checklist. This E2E flow and its tests remain dry-run-only and never run `APPLY=1`. See [memory-approval-manual-store-runbook.md](memory-approval-manual-store-runbook.md).
