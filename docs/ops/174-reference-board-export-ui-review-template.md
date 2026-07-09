# Reference Board Export UI Review Template

Use this template when reviewing the M34.25 dashboard export UI.

## Review Fields

- Date/time:
- Dashboard URL:
- Active board selected?
- Export JSON button visible?
- Export Markdown button visible?
- JSON export panel opens?
- Markdown export panel opens?
- Copy button works?
- Export uses board_id only?
- No absolute host paths shown?
- No asset copy/move/delete?
- No generation button?
- No ZIP/PDF/download implemented?
- Git safety result:
- Issues found:

## Suggested Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

Expected:

- Select a reference board.
- Export JSON opens formatted JSON in a read-only panel.
- Export Markdown opens Markdown text in a read-only panel.
- Copy copies panel text if browser clipboard access is available.
- No source assets are copied, moved, deleted, renamed, approved, or generated.
