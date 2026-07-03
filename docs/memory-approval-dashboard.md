# Memory Approval Dashboard

Milestone 29.8 adds read-only Gateway and Dashboard visibility for the memory approval workflow.

Gateway endpoint:

```text
GET /gateway/memory-approval/dashboard
```

The endpoint reads fixed runtime reports only:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json
```

## Dashboard View

The Dashboard UI shows a read-only Memory Approval section with candidate totals, approved and blocked counts, duplicate groups, dry-run attempt counts, stored/failed/skipped counts, E2E dry-run status, approval file presence, latest apply attempt time, compact candidate cards, duplicate groups, and warnings.

## Safety

This view does not approve candidates, create approval files, edit approval files, run scripts, run `APPLY=1`, call Memory API, write memories, call Gateway-to-Memory write routes, call llama-server, expose raw prompts or responses, switch models, control Docker, train, or fine-tune models.

Missing runtime reports are surfaced as warnings instead of endpoint failures.

Milestone 29.9 uses this read-only view in the manual store runbook. Run `make memory-store-manual-preflight` before any human-run `APPLY=1 make memory-store-approved`; dashboard tests and preflight tests never run `APPLY=1`. See [memory-approval-manual-store-runbook.md](memory-approval-manual-store-runbook.md).
