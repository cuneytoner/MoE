# Reference Board Export Security Policy

## Purpose

Reference board exports must produce review artifacts without weakening runtime, model, Git, or media safety boundaries.

M34.23 returns response-only JSON and does not create export files.

## Explicit Deny

Reference board export must not allow:

- arbitrary paths
- absolute host paths by default
- model files
- secrets
- shell execution
- generation triggers
- delete, move, or rename actions
- source asset modification
- symlink traversal
- hidden files
- export outside a controlled response or controlled runtime export folder
- direct SVG embedding until an SVG policy exists
- external upload
- automatic approval of outputs

## Allowed

Reference board export may include:

- board JSON data
- `relative_runtime_path` references
- safe metadata summaries
- item selected_reason
- item tags
- safety flags
- optional future controlled copy mode only in a later milestone

## Path Rules

Export implementations should derive data from:

- stored reference-board JSON
- output-card scans
- card_id-based metadata reads

Export implementations must not accept arbitrary paths from clients.

## Metadata Rules

Metadata inclusion should be summary-only by default.

The export should avoid secrets, model paths, hidden files, large raw metadata blobs, and any file outside allowlisted runtime output roots.

## Asset Handling Rules

Default export must be manifest-only.

Source assets must remain untouched:

- no copy
- no move
- no delete
- no rename
- no mutation
- no approval

Future controlled copy mode requires a separate implementation milestone and review.

## SVG Rules

Do not directly embed SVG in Markdown or HTML exports until a dedicated SVG sanitization and serving policy exists.

SVG references may be included as `relative_runtime_path` values.
