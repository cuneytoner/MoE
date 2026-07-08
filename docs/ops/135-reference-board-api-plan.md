# Reference Board API Plan

## Future Endpoints

```text
GET /gateway/media/reference-boards
GET /gateway/media/reference-boards/{board_id}
POST /gateway/media/reference-boards
POST /gateway/media/reference-boards/{board_id}/items
DELETE /gateway/media/reference-boards/{board_id}/items/{item_id}
```

## Safety Rules

- APIs may create/edit board JSON only under allowlisted runtime board folder.
- APIs must not alter source assets.
- APIs must validate `relative_runtime_path` against output cards.
- APIs must not accept arbitrary absolute paths.
- APIs must not trigger generation.
- APIs must not execute shell.
- APIs must not expose arbitrary filesystem browsing.

## Data Validation

Future API implementation should validate board IDs, item IDs, asset types, safety labels, and selected reasons. It should reject paths outside runtime and reject items that do not match known output cards.

Future reference board API endpoints should use the M34.16 safe runtime store helpers.

## Non-goals

- No asset copying by default.
- No delete/move/rename of generated assets.
- No generation controls.
- No engineering approval workflow.
