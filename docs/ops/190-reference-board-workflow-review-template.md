# Reference Board Workflow Review Template

Use this template when reviewing the completed reference board workflow.

## Review Fields

- Date/time:
- Dashboard URL:
- Board id:
- Output card exists?
- Metadata visible?
- Board create/select works?
- Add item works?
- Edit note/tags works?
- Export JSON works?
- Export Markdown works?
- Download JSON works?
- Download Markdown works?
- Regression script passes?
- Safety invariants checked?
- No host path leakage?
- Git safety result:
- Issues found:
- Next action:

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

This review should not create runtime export files, generated images, ZIP/PDF files, source asset copies, or model files.
