# Reference Board Validation Limits Review Template

Use this template when reviewing M34.35 validation behavior.

## Review Fields

- Date/time:
- Commit:
- board_id valid accepted?
- board_id invalid rejected?
- title limit checked?
- description limit checked?
- selected_reason limit checked?
- tag count limit checked?
- tag length limit checked?
- tag character policy checked?
- dashboard hints visible?
- regression passes?
- no traceback leakage?
- no host path leakage?
- Git safety result:
- Issues found:

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
