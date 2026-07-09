# Reference Board Export Polish

## What Was Polished

M34.31 improves the dashboard wording and grouping for reference board export and download actions.

The backend endpoints did not change.

## UI Sections

The active reference board now separates actions into two sections:

- Review exports
- Downloads

## Export Vs Download Distinction

Review exports open read-only panels inside the dashboard:

- Export JSON
- Export Markdown

Downloads save response-only review artifacts through browser attachment handling:

- Download JSON
- Download Markdown

The dashboard help text says:

```text
Exports open read-only review panels. Downloads save response-only review artifacts.
```

## Copy Feedback Behavior

Export panels keep the existing copy behavior.

After a successful copy, the panel shows:

```text
Copied
```

If the browser clipboard API is unavailable or the copy fails, the panel shows an error message.

## Safety Note

The action area keeps one clear safety note:

```text
These actions do not copy, move, delete, approve, or generate source assets.
```

## What Did Not Change

M34.31 does not add:

- backend endpoints
- ZIP export
- PDF export
- runtime export files
- source asset copy/move/delete behavior
- approval actions
- generation actions
- arbitrary filesystem browsing

Export and download URLs still use the reference board id, not asset paths.

## How To Review

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build dashboard-ui
```

### Open in browser
```text
http://127.0.0.1:8500/#media
```

Expected:

- Active board selected.
- Review exports section visible.
- Downloads section visible.
- Export buttons open read-only panels.
- Download buttons save attachments.
- Safety note appears once.
- No generation/delete/move/approve action exists.
