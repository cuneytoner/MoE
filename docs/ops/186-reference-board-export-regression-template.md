# Reference Board Export Regression Template

Use this template when recording a reference board export/download regression run.

## Review Fields

- Date/time:
- Board id:
- Gateway URL:
- JSON export OK?
- Markdown export OK?
- JSON download OK?
- Markdown download OK?
- Headers OK?
- Safety flags OK?
- Host path leakage absent?
- Runtime export files absent?
- Temporary files only under `/tmp`?
- Issues found:
- Git safety result:

## Command Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-export-regression
```

### Run on PC-1 with custom board
```bash
BOARD_ID=api-test-board make reference-board-export-regression
```

Expected:

```text
Reference board export regression OK
```

## Notes

The regression script should not create runtime export files, generated images, ZIP/PDF files, or source asset copies.
