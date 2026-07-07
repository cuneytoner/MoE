# 51 Media Dashboard Output Review

This guide explains how to inspect generated image outputs through the media dashboard status.

It covers both the direct ComfyUI first-image path and the Gateway/media image path.

After controlled variant generation, use dashboard `latest_images` to confirm the newest outputs.

## What This Guide Is For

- Confirm generated images are visible through dashboard status.
- Understand the `latest_images` list.
- Compare dashboard paths with filesystem paths.
- Confirm generated outputs remain outside Git.
- Collect useful evidence when dashboard output looks wrong.

## What This Guide Does NOT Do

- It does not run real image generation.
- It does not add dashboard write actions.
- It does not start or stop services.
- It does not alter Gateway behavior.
- It does not alter Docker Compose.
- It does not add shell execution features.
- It does not delete or move generated images.

## Dashboard Safety Contract

The media dashboard is read-only.

Expected dashboard safety flags:

| Flag | Expected value | Meaning |
| --- | --- | --- |
| `starts_services` | `false` | Dashboard does not start services |
| `stops_services` | `false` | Dashboard does not stop services |
| `real_generation_trigger` | `false` | Dashboard does not trigger generation |
| `arbitrary_shell` | `false` | Dashboard does not execute arbitrary shell commands |

If any of these appear different, stop and inspect before using the dashboard output as trusted evidence.

## How To Open/Read Dashboard Status

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make media-dashboard-status
```

Expected good sign: dashboard status returns service and safety metadata, including `latest_images` when runtime outputs are visible.

## How latest_images Is Structured

`latest_images` is a read-only list of recent generated image files.

Each item currently includes:

- `name`
- `path`
- `modified`
- `size_bytes`

Known output example:

```text
moe_flux_first_20260706_133441_00001_.png
```

See [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) for the field reference.

## How To Confirm A New Image Appears

First ask the image helper for latest outputs:

### Run on PC-1

```bash
make image-latest
```

Then list recent PNG files directly from runtime storage:

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -30
```

Expected good sign: the newest expected PNG appears under `/home/cuneyt/MoE/runtime/media/outputs/images`.

## How To Compare Dashboard Path With Filesystem Path

Compare the dashboard `latest_images[].path` value with the filesystem listing.

They should both point under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

If dashboard shows `moe_flux_first_20260706_133441_00001_.png`, the filesystem listing should show the same filename somewhere under runtime media outputs.

Dashboard paths should not point inside:

```text
/home/cuneyt/DiskD/Projects/MoE/codebase
```

## How To Confirm Generated Outputs Are Outside Git

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: generated images, model files, and checkpoints do not appear as tracked or staged repo files.

Dashboard visibility does not mean the file is committed to Git.

## What Dashboard Does Not Show Yet

The current dashboard output review does not replace manual notes.

It may not show:

- Prompt text
- Seed
- Steps
- Workflow JSON path
- Keep/reject decision
- Visual comparison notes
- Whether the image was archived

Record those details manually with [53-media-dashboard-review-template.md](53-media-dashboard-review-template.md) and the relevant generation evidence template.

## What To Paste Back If Dashboard Looks Wrong

Paste:

- `make media-dashboard-status` output
- `make image-latest` output
- The filesystem `find` output
- `git status --short`
- Whether `latest_images` includes the expected filename
- Whether dashboard paths point under runtime media outputs
- Any unexpected safety flag values
