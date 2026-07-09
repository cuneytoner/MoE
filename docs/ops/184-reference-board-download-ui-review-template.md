# Reference Board Download UI Review Template

Use this template when reviewing the M34.29 dashboard download UI.

## Review Fields

- Date/time:
- Dashboard URL:
- Active board selected?
- Download JSON visible?
- Download Markdown visible?
- Download JSON triggers .json attachment?
- Download Markdown triggers .md attachment?
- URLs use board_id only?
- No asset path used in URL?
- No source asset download?
- No ZIP/PDF?
- No generation button?
- No delete/move/rename?
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
- Download JSON is visible.
- Download Markdown is visible.
- Download JSON uses `/download/json`.
- Download Markdown uses `/download/markdown`.
- Download URLs use `board_id`, not source asset paths.
- No source assets are copied, moved, deleted, renamed, downloaded, or generated.
