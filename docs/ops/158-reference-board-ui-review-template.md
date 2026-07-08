# Reference Board UI Review Template

Use this template when reviewing the dashboard reference-board UI.

## Review Fields

- Date/time:
- Dashboard URL:
- Gateway URL:
- Board list visible?
- Create board works?
- Active board selectable?
- Active board item count visible?
- Output card `Add to board` visible only when a board is active?
- Add selected card works?
- Duplicate add shows `Already in board.`?
- Board item appears with name and relative runtime path?
- `Remove from board` removes only the board reference?
- Safety note visible?
- No arbitrary path usage?
- No asset copy/move/delete/rename buttons?
- No approve button?
- No generation button?
- No shell action?
- No service control?
- Reference-board API status:
- Git safety result:
- Issues found:
- Questions/blockers:

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
http://127.0.0.1:8500
```

### Run on PC-1
```bash
git status --short
```
