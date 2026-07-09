# Reference Board JSON Download Review Template

Use this template when reviewing the M34.28 JSON download endpoint.

## Review Fields

- Date/time:
- Board id:
- Endpoint status:
- Content-Type application/json?
- Content-Disposition attachment?
- Filename safe?
- Filename uses sanitized board_id?
- JSON valid?
- Export content matches JSON export endpoint?
- Safety flags correct?
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
curl -fsS -D /tmp/moe-reference-board-json-download-headers \
  http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/download/json \
  -o /tmp/moe-reference-board-download.json
```

### Run on PC-1
```bash
grep -Ei 'content-type:|content-disposition:' /tmp/moe-reference-board-json-download-headers
```

### Run on PC-1
```bash
jq '.export_type, .board.board_id, .board.item_count, .safety' /tmp/moe-reference-board-download.json
```

### Run on PC-1
```bash
grep -E '/home/cuneyt|/mnt|/media' /tmp/moe-reference-board-download.json
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
