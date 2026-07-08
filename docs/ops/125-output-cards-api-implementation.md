# Output Cards API Implementation

## What Was Implemented

M34.5 adds the first read-only Gateway API endpoint for media output cards.

Endpoint:

```text
GET /gateway/media/output-cards
```

The endpoint scans only allowlisted runtime output folders and returns safe card metadata for generated images and SVG drawings.

M34.6 consumes this endpoint in dashboard UI.

M34.7.1 mounts drawing runtime folders read-only so `drawing_svg` cards can be discovered from the Gateway container.

## Response Fields

Top-level response fields:

- `status`
- `service`
- `safety`
- `allowlisted_roots`
- `max_cards`
- `cards`

Card fields:

- `id`
- `type`
- `name`
- `path`
- `relative_runtime_path`
- `modified`
- `size_bytes`
- `preview_available`
- `source`
- `tags`
- `safety_label`
- `metadata_available`
- `metadata_path`
- `notes`

## Safety Rules

- read-only
- no service start
- no service stop
- no shell execution
- no generation trigger
- no delete
- no move
- no rename
- no arbitrary filesystem browsing
- no user-provided scan paths

## Allowlisted Folders

```text
/home/cuneyt/MoE/runtime/media/outputs/images
/home/cuneyt/MoE/runtime/pergola/drawings
/home/cuneyt/MoE/runtime/drawings
```

## Supported Extensions

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`
- `.svg`

Model and checkpoint extensions are excluded.

## Metadata Sidecar Behavior

The endpoint looks for a sidecar JSON file with the same basename:

```text
example.png -> example.json
side_elevation.svg -> side_elevation.json
```

It returns:

- `metadata_available: true` when the sidecar exists.
- `metadata_path` when the sidecar exists.

Full metadata parsing/display remains planned.

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards | jq .
```

### Run on PC-1
```bash
make media-output-cards-status
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/output-cards | jq '.cards[0:5]'
```

## How To Inspect Response

Check the safety block first, then review `allowlisted_roots`, `max_cards`, and a few card paths. Card paths should point under runtime only.

## What Is NOT Implemented Yet

- Dashboard UI cards.
- Full sidecar metadata parsing.
- PDF/DXF cards.
- Reference-board selection.
- Compare view.
- Rerun actions.
- Generation controls.

## Next Steps

- Add dashboard output cards UI.
- Implement sidecar metadata writing.
- Add metadata parsing and detail display.
- Plan reference-board selection on top of cards.
