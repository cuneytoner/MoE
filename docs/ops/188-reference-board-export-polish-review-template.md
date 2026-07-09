# Reference Board Export Polish Review Template

Use this template when reviewing the M34.31 dashboard polish.

## Review Fields

- Date/time:
- Dashboard URL:
- Active board selected?
- Review exports section visible?
- Downloads section visible?
- Export JSON opens panel?
- Export Markdown opens panel?
- Copy works?
- Copy feedback shown?
- Download JSON works?
- Download Markdown works?
- Safety note visible once?
- No duplicate warning clutter?
- No approve/delete/move/generate buttons?
- URLs use board_id only?
- Git safety result:
- Issues found:

## Command Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build dashboard-ui
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

## Notes

This review is UI polish only. It should not create runtime export files, ZIP/PDF files, generated images, or source asset copies.
