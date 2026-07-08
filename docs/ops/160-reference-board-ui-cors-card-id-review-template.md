# Reference Board UI CORS + Card ID Review Template

Use this template when reviewing the M34.12.1 browser fix.

## Review Fields

- Date/time:
- Dashboard URL:
- Add to board works?
- POST preflight succeeds?
- DELETE works?
- React duplicate key warnings gone?
- Output card ids unique?
- Preview endpoint still works?
- Metadata endpoint still works?
- Source assets untouched?
- No generation triggered?
- Git safety result:
- Issues found:

## Suggested Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards \
  | jq -r '.cards[].id' \
  | sort | uniq -d
```

### Run on PC-1
```bash
curl -fsS -X OPTIONS http://127.0.0.1:8100/gateway/media/reference-boards/smoke-test-board/items \
  -H 'Origin: http://127.0.0.1:8500' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Content-Type' \
  -D /tmp/moe-reference-board-cors-headers
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

### Run on PC-1
```bash
git status --short
```
