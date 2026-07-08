# Media Dashboard Output Cards Plan

## Why Output Cards Are Needed

The media workflow now produces more than one kind of output. Generated images, deterministic SVG drawings, future PDFs, prompt packs, and reference boards need a shared dashboard display model.

Output cards give operators a safe way to review outputs without opening arbitrary folders, triggering generation, or guessing which files are newest.

## Current State

- The media dashboard status can report `latest_images`.
- Generated images live under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Pergola SVG drawings live under `/home/cuneyt/MoE/runtime/pergola/drawings`.
- Generic drawing engine demo SVGs live under `/home/cuneyt/MoE/runtime/drawings/demo`.
- Dashboard behavior is read-only.

## Target State

The dashboard should eventually show generated media and drawings as read-only output cards. Cards should make it easy to inspect name, type, path, modified time, file size, source, tags, and safety label.

Output cards should use sidecar metadata when available.

## Output Types

- `image`
- `drawing_svg`
- `drawing_pdf` later
- `prompt_pack` later
- `reference_board` later

Output type examples:

- `image`
- `drawing_svg`
- `drawing_pdf`
- `reference_board`
- `prompt_pack`

## Card Fields

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
- `notes`
- `safety_label`
- `metadata_available`
- `metadata_path`

## Safety Labels

- `visual_reference_only`
- `draft_drawing`
- `deterministic_drawing`
- `not_construction_document`
- `generated_media`

## Safety Policy

Output cards must be read-only. They should help review existing files, not create, move, rename, delete, or generate anything.

The future card system must preserve the current dashboard safety policy:

- no service start
- no service stop
- no arbitrary shell
- no real generation trigger

## Read-only Constraints

- Cards can display metadata from allowlisted runtime folders.
- Cards can expose copyable paths for operator review.
- Cards must not expose arbitrary filesystem browsing.
- Cards must not include destructive actions.
- Cards must not include generation buttons.

## Runtime Paths

Allowlisted runtime output roots for future cards:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
/home/cuneyt/MoE/runtime/pergola/drawings
/home/cuneyt/MoE/runtime/drawings
```

## What This Milestone Does NOT Implement

- No API implementation.
- No UI implementation.
- No runtime folder scan.
- No generated image or drawing creation.
- No Gateway runtime behavior change.
- No Docker compose behavior change.

## Next Milestones

- Define metadata capture for prompts and outputs.
- Implement a read-only output cards API.
- Implement dashboard output cards UI.
- Add reference-board and compare workflows after card behavior is stable.
