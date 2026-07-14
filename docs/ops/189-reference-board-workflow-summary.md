# Reference Board Workflow Summary

## Purpose

Reference boards curate selected output card references for review without copying, moving, deleting, approving, or generating source assets.

They are for operator review and future workflow planning. A board records references, selected reasons, tags, and review metadata while leaving the original media or drawing files in place.

M34.33 introduces a hardening plan for validation, runtime-store resilience, export/download safety, and dashboard failure states.

For failures, use the M34.34 error handling policy and review template.

Reference board inputs now have explicit validation limits.

## Runtime Locations

- Reference board JSON files live under runtime reference board storage.
- Source assets remain in their original runtime media or drawing locations.
- Metadata sidecars stay next to, or associated with, their source output artifacts.
- Exports and downloads are response-only unless a future milestone explicitly changes this.

The source repo must stay source-only. Runtime board data, generated media, drawings, model files, logs, secrets, and downloaded review artifacts do not belong in Git.

## Main Flow

1. Output card exists.
2. Metadata sidecar exists.
3. Dashboard lists output cards.
4. User creates or selects a reference board.
5. User adds an output card reference to the board.
6. User reviews the board item.
7. User edits selected reason and tags.
8. User views metadata.
9. User exports JSON or Markdown to a read-only panel.
10. User downloads JSON or Markdown attachment.
11. Regression script validates export/download behavior.

## API Endpoints

```text
GET /gateway/media/output-preview/{card_id}
GET /gateway/media/output-card-metadata/{card_id}
GET /gateway/media/reference-boards
GET /gateway/media/reference-boards/{board_id}
POST /gateway/media/reference-boards
POST /gateway/media/reference-boards/{board_id}/items
PATCH /gateway/media/reference-boards/{board_id}/items/{item_id}
DELETE /gateway/media/reference-boards/{board_id}/items/{item_id}
GET /gateway/media/reference-boards/{board_id}/export/json
GET /gateway/media/reference-boards/{board_id}/export/markdown
GET /gateway/media/reference-boards/{board_id}/download/json
GET /gateway/media/reference-boards/{board_id}/download/markdown
```

## Dashboard Flow

Open the Media page and use the Reference Boards section.

The dashboard includes:

- Board list
- Active board detail
- Board item cards
- Review exports section
- Downloads section
- Metadata panel
- Note/tag edit controls

Board item cards show the referenced output, preview behavior when available, safety labels, tags, selected reason, relative runtime path, and metadata access.

## Export And Download Behavior

JSON export is a machine-readable review pack.

Markdown export is a human-readable review pack.

Export buttons open read-only review panels in the dashboard. Download buttons call response-only attachment endpoints. Download endpoints use `Content-Disposition: attachment`.

Download filenames use a safe `board_id` and UTC timestamp. No runtime export files are created.

## Regression

Use the regression target to validate the export/download contract.

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
make reference-board-export-regression
```

The script validates:

- JSON export works
- Markdown export works
- JSON download works
- Markdown download works
- download headers are correct
- safety flags are correct
- obvious host paths are absent
- downloaded JSON is valid
- downloaded Markdown includes expected review sections
- no runtime export files are created

Expected output:

```text
Reference board export regression OK
BOARD_ID=api-test-board
GATEWAY_API_URL=http://127.0.0.1:8100
```

## Safety Invariants

- no source asset copy
- no source asset move
- no source asset delete
- no approve action
- no generation trigger
- no shell execution
- no arbitrary filesystem browsing
- no ZIP/PDF in this phase
- no model files
- no secrets
- no absolute host path leakage

## Troubleshooting

Board not visible:

Confirm the dashboard can reach Gateway, then refresh the Media page.

Item not added:

Confirm an active board is selected and the output card still exists in the output card API.

Export returns 404:

Confirm the `board_id` exists and the export URL is built from the board id, not an asset path.

Download does not start:

Confirm the browser did not block the attachment and that Gateway is serving the download endpoint.

Stale dashboard container:

Rebuild the dashboard container and reload the browser tab.

Regression fails:

Confirm Gateway is running, the default board exists, and the failure message does not indicate a safety invariant violation.

Accidental untracked file such as `main`:

Run `git status --short`, inspect the file, and do not commit it unless it is intentionally source-controlled.

## Next Milestones

- M34.33 Reference Board Hardening Plan
- M34.34 Reference Board Error Handling Polish
- M35 Media Review Workflow Phase
