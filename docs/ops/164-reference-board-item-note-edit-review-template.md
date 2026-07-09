# Reference Board Item Note Edit Review Template

Use this template when reviewing M34.21 reference board item note editing.

## Review Fields

- Date/time:
- Board id:
- Item id:
- PATCH endpoint OK?
- `selected_reason` updated?
- tags updated?
- `card_id` unchanged?
- `relative_runtime_path` unchanged?
- source asset still exists?
- metadata sidecar still exists?
- dashboard edit UI works?
- no asset delete/move/rename?
- no generation button?
- no arbitrary path usage?
- Git safety result:
- Issues found:

## Suggested Checks

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

### Run on PC-1
```bash
git status --short
```
