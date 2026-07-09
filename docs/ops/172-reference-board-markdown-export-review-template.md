# Reference Board Markdown Export Review Template

Use this template when reviewing the M34.24 Markdown export endpoint.

## Review Fields

- Date/time:
- Board id:
- Endpoint status:
- Content-Type text/markdown?
- title included?
- board metadata included?
- item list included?
- selected_reason included?
- tags included?
- metadata summary included?
- absolute paths excluded?
- source assets untouched?
- generation_triggered false?
- source_assets_copied false?
- source_assets_deleted false?
- model files excluded?
- secrets excluded?
- Markdown readable?
- Git safety result:
- Issues found:

## Suggested Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS -D /tmp/moe-reference-board-markdown-headers \
  http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/markdown
```

### Run on PC-1
```bash
grep -i '^content-type:' /tmp/moe-reference-board-markdown-headers
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/markdown \
  | grep -E '/home/cuneyt|/mnt|/media'
```

Expected: no output.
