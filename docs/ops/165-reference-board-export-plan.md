# Reference Board Export Plan

## Why Export Is Needed

Reference boards collect selected generated assets, notes, tags, and metadata into a reviewable set.

Export is needed so an operator can share or archive a board summary without committing binary media files, moving source assets, or turning draft outputs into approvals.

## Current Board Capability

Reference boards currently support:

- list/read/create boards
- add/remove output card references
- item detail view
- image previews through `card_id`
- metadata view through `card_id`
- selected_reason and tags editing

## Proposed Export Formats

- JSON review pack
- Markdown review pack
- manifest-only mode
- future ZIP mode

ZIP export is explicitly deferred.

## Recommended First Implementation

M34.23 should implement:

```text
GET /gateway/media/reference-boards/{board_id}/export/json
```

Later, M34.24 should implement:

```text
GET /gateway/media/reference-boards/{board_id}/export/markdown
```

Do not implement export endpoints in this planning milestone.

M34.23 implements the JSON review pack endpoint.

M34.24 implements the Markdown review pack endpoint.

M34.25 implements dashboard UI access to JSON and Markdown export endpoints.

M34.26 plans response-only download behavior for JSON and Markdown exports.

## JSON Review Pack

The JSON review pack should return a structured review artifact containing board metadata, selected item references, selected reasons, tags, and safe metadata summaries.

It should not copy source assets.

## Markdown Review Pack

The Markdown review pack should be human-readable and include:

- title
- board metadata
- item table
- selected_reason
- tags
- relative_runtime_path
- metadata summary
- safety note

Markdown export should be review-only and should not embed SVG directly until an SVG policy exists.

## Manifest-only Mode

Manifest-only export should include references and metadata summaries without media bytes.

This is the preferred default for safe sharing and Git hygiene.

## Future ZIP Mode

ZIP export is deferred to a later milestone.

If implemented later, it must be explicit, controlled, and audited. It must not move, delete, rename, mutate, or approve source assets.

## Data Included

- `board_id`
- title
- description
- created_at
- updated_at
- safety_label
- item_count
- items
- `item.card_id`
- `item.asset_type`
- `item.name`
- `item.relative_runtime_path`
- `item.selected_reason`
- `item.tags`
- `item.safety_label`
- `item.added_at`
- metadata summary if available
- image/drawing source info if available

## Data Excluded

- absolute host paths by default
- model files
- secrets
- raw source asset bytes
- hidden files
- symlink targets
- generated ZIP/PDF files in this milestone
- approval status for construction or production use

## Safety Rules

- no arbitrary filesystem browsing
- no absolute path export by default
- no model files
- no secrets
- no shell execution
- no generation trigger
- no asset mutation
- no asset deletion
- no external upload
- no automatic approval of outputs
- exports are review artifacts only

## Path Handling Rules

Exports should use `relative_runtime_path` references by default.

Export implementations must resolve data through existing board records and output-card metadata. They must not accept arbitrary paths from the client.

## Metadata Inclusion Strategy

Metadata should be summarized into stable, review-friendly fields.

Missing metadata should be represented as unavailable, not treated as an error that blocks the whole export.

## What Is Not Implemented Yet

- no ZIP export
- no PDF export
- no generated export files
- no asset copy mode
- no download-to-file export

## Future Implementation Milestones

- M34.23 Reference Board JSON Export Implementation
- M34.24 Reference Board Markdown Export Implementation
- M34.25 Reference Board Export UI
- M34.26 Reference Board Export Download Plan
- M34.27 Reference Board Markdown Download Implementation
- M34.28 Reference Board JSON Download Implementation
- M34.29 Reference Board Download UI
