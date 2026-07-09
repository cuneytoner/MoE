# Reference Board Download Security Policy

## Purpose

Reference board downloads must behave like response-only review exports. They must not become a filesystem browser, asset packager, source asset copier, or generation trigger.

## Explicit Deny

Reference board download must not allow:

- arbitrary path
- write to runtime export folder
- asset copy
- asset delete
- asset move
- asset rename
- generation trigger
- shell execution
- model files
- secrets
- ZIP
- PDF
- SVG embedding
- image embedding
- absolute host paths
- external upload
- source asset mutation

## Allowed

Reference board download may allow:

- response-only JSON attachment
- response-only Markdown attachment
- safe `Content-Disposition` filename
- content generated from existing export helpers
- sanitized `board_id` route values
- server-generated UTC timestamp in filename

## Content Source

Downloads should derive content from existing export helpers:

- JSON from the JSON review pack helper
- Markdown from the Markdown review pack helper

Download endpoints must not accept arbitrary filesystem paths from the client.

## Runtime Write Policy

Do not create runtime export files by default.

Do not create:

- `/home/cuneyt/MoE/runtime/reference-boards/exports`
- temporary ZIP files
- temporary PDF files
- copied source assets

Runtime export archival must be a separate explicit milestone if needed later.

M34.27 does not create runtime export files and returns response-only Markdown attachment.

## Attachment Policy

Use response headers only:

```text
Content-Disposition: attachment
```

The filename must follow the safe filename policy in `176-reference-board-download-filename-policy.md`.
