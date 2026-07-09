# Reference Board Download Review Template

Use this template when reviewing future reference-board download endpoints.

Use [180-reference-board-markdown-download-review-template.md](180-reference-board-markdown-download-review-template.md) for Markdown implementation-specific review.

Use [182-reference-board-json-download-review-template.md](182-reference-board-json-download-review-template.md) for JSON implementation-specific review.

## Review Fields

- Date/time:
- Board id:
- Download type:
- Endpoint tested:
- HTTP status:
- Content-Type correct?
- Content-Disposition attachment?
- Filename safe?
- Filename uses sanitized board_id?
- Export content matches non-download endpoint?
- No runtime export file created?
- Source assets untouched?
- No generation triggered?
- Absolute paths excluded?
- Git safety result:
- Issues found:

## Suggested Future Checks

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS -D /tmp/moe-reference-board-download-headers \
  http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/download/markdown
```

### Run on PC-1
```bash
grep -Ei 'content-type:|content-disposition:' /tmp/moe-reference-board-download-headers
```

Expected:

- `Content-Type` matches the download type.
- `Content-Disposition` is `attachment`.
- Filename begins with `reference-board-api-test-board-`.
- Filename ends with `.json` or `.md`.

## Safety Notes

Download review should confirm:

- no runtime export file was created
- source assets were not copied, moved, deleted, renamed, or approved
- no generation was triggered
- no ZIP/PDF was created
- no absolute host paths are present in exported content
