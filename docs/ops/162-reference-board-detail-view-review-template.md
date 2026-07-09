# Reference Board Detail View Review Template

Use this template when reviewing the M34.19 reference-board detail view.

## Review Fields

- Date/time:
- Dashboard URL:
- Active board visible?
- Board detail header visible?
- Board item cards visible?
- Image item preview works?
- SVG item placeholder works?
- Metadata action works?
- Remove from board works?
- Source asset still exists?
- Metadata sidecar still exists?
- No duplicate key warnings?
- No CORS errors?
- No generation button?
- No asset delete/move/rename?
- No arbitrary path usage?
- Git safety result:
- Issues found:

## Suggested Checks

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards | jq .
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

### Run on PC-1
```bash
git status --short
```
