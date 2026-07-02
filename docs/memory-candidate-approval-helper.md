# Memory Candidate Approval Helper

Milestone 29.6 adds a helper-only review step for memory candidates.

It reads, when present:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json
```

It writes a runtime helper report:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json
```

It also writes an example approval file:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json
```

The real approval file is never created by the helper:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

The dry-run E2E workflow can create a temporary test approval fixture at the real approval path only when `USE_TEST_APPROVAL_FIXTURE=1` is set. It marks the file as `test_fixture: true`, removes it by default, and never runs `APPLY=1`. See [memory-approval-dry-run-e2e.md](memory-approval-dry-run-e2e.md).

## Commands

Generate the helper report and example file:

```bash
make memory-candidate-approval-helper-local
```

Print a compact candidate list:

```bash
make memory-candidate-list-local
```

Run the local test:

```bash
make test-memory-candidate-approval-helper
```

## Human Approval Flow

1. Inspect `memory-candidate-approval-helper-report.json`.
2. Choose candidate ids manually.
3. Copy `approved-memory-candidates.example.json` to `approved-memory-candidates.json`.
4. Edit `approved_candidate_ids` manually.
5. Run `make memory-store-plan-local`.
6. Inspect `memory-store-plan.json`.
7. Run `make memory-store-approved` for dry-run.
8. Only then optionally run `APPLY=1 make memory-store-approved`.

## Safety

This helper does not:

- approve candidates automatically
- create the real approval file
- call Memory API
- write memories
- call Gateway or llama-server
- include raw prompts
- include raw model responses
- include individual feedback records
- switch models
- control Docker
- train or fine-tune models
- commit generated runtime reports
