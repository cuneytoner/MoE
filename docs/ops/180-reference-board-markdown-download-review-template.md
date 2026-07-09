# Reference Board Markdown Download Review Template

Use this template when reviewing the M34.27 Markdown download endpoint.

## Review Fields

- Date/time:
- Board id:
- Endpoint status:
- Content-Type text/markdown?
- Content-Disposition attachment?
- Filename safe?
- Filename uses sanitized board_id?
- Markdown content valid?
- Export content matches markdown export endpoint?
- No runtime export file created?
- Source assets untouched?
- No generation triggered?
- Absolute paths excluded?
- Git safety result:
- Issues found:

## Suggested Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS -D /tmp/moe-reference-board-md-download-headers \
  http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/download/markdown \
  -o /tmp/moe-reference-board-download.md
```

### Run on PC-1
```bash
grep -Ei 'content-type:|content-disposition:' /tmp/moe-reference-board-md-download-headers
```

### Run on PC-1
```bash
head -n 20 /tmp/moe-reference-board-download.md
```

### Run on PC-1
```bash
grep -E '/home/cuneyt|/mnt|/media' /tmp/moe-reference-board-download.md
```

Expected: no output.

## Safety Notes

Confirm that the endpoint did not:

- create runtime export files
- copy source assets
- move source assets
- delete source assets
- trigger generation
- create ZIP/PDF files
