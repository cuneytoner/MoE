# Reference Board Error Handling Review Template

Use this template when reviewing M34.34 error handling behavior.

## Review Fields

- Date/time:
- Commit:
- invalid board id tested?
- missing board tested?
- duplicate board tested?
- missing item tested?
- missing output card tested?
- malformed board behavior reviewed?
- export error behavior reviewed?
- dashboard error messages reviewed?
- no traceback leakage?
- no host path leakage?
- regression script passes?
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
