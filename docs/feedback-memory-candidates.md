# Feedback Memory Candidate Review

Milestone 29.2 adds a memory candidate review generator.

It reads any available aggregate runtime reports:

```text
/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json
/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json
/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json
/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json
```

It writes human-reviewable memory candidates under runtime:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
```

## Commands

```bash
make feedback-memory-candidates-local
make test-feedback-memory-candidates
```

Missing inputs are allowed. The report includes input availability metadata and still writes a valid review packet.

## Safety

This milestone does not:

- write to Memory API
- call Memory API
- train or fine-tune models
- modify memory
- apply generated memory candidates automatically
- modify router config
- modify prompt templates
- call Gateway or llama-server
- depend on PC2 availability
- include raw prompts
- include raw model responses
- include individual feedback records
- commit generated runtime reports

Candidates are short project-level lessons only. A human must inspect and approve each candidate before any later memory storage workflow.

Milestone 29.3 adds that later workflow:

```bash
make memory-store-plan-local
make memory-store-approved
```

It remains dry-run by default. Memory API writes require a human-created approval file and explicit `APPLY=1`. See [memory-store-workflow.md](memory-store-workflow.md).

The next review step can audit duplicate memory candidate groups before approval:

```bash
make memory-store-audit-local
```

See [memory-store-audit.md](memory-store-audit.md).

Approved store attempts can later be audited through the append-only apply log. See [memory-store-apply-log.md](memory-store-apply-log.md).

The manual approval helper can prepare a review report and example approval file without approving candidates automatically:

```bash
make memory-candidate-approval-helper-local
make memory-candidate-list-local
```

See [memory-candidate-approval-helper.md](memory-candidate-approval-helper.md).
