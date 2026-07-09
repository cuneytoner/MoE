# Reference Board Hardening Review Template

Use this template when reviewing the reference board hardening plan and follow-up risks.

## Review Fields

- Date/time:
- Reviewer:
- Current commit:
- Board id:
- Regression script result:
- Input validation gaps reviewed?
- Runtime store gaps reviewed?
- Export/download gaps reviewed?
- Dashboard gaps reviewed?
- Recovery playbook reviewed?
- Non-goals confirmed?
- New risks found?
- Follow-up milestones:
- Git safety result:

## Command Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-export-regression
```

Expected:

```text
Reference board export regression OK
```

## Notes

This review should not create runtime export files, generated images, ZIP/PDF files, source asset copies, approval workflows, generation workflows, or shell execution paths.
