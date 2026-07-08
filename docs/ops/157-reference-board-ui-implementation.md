# Reference Board UI Implementation

## What Was Implemented

M34.12 adds dashboard UI support for reference boards.

The dashboard can list boards, create a board, select an active board, add output cards to the active board, show board items, and remove item references from a board.

## API Endpoints Used

```text
GET /gateway/media/reference-boards
GET /gateway/media/reference-boards/{board_id}
POST /gateway/media/reference-boards
POST /gateway/media/reference-boards/{board_id}/items
DELETE /gateway/media/reference-boards/{board_id}/items/{item_id}
```

The UI addresses boards by `board_id`, items by `item_id`, and assets by `card_id`.

## Board Creation

The create form accepts:

- `board_id`
- `title`
- `description`

The form creates only a reference-board JSON record under the safe runtime reference-board store.

## Output Card Selection

When an active board is selected, output cards show:

```text
Add to board
```

The dashboard sends:

```json
{
  "card_id": "card id from output card",
  "selected_reason": "Selected from dashboard output cards.",
  "tags": ["existing", "card", "tags"]
}
```

The UI does not send asset paths, metadata paths, or relative runtime paths when adding an item.

## Duplicate Behavior

If the API returns a duplicate-item response, the dashboard shows:

```text
Already in board.
```

The source asset and board remain usable.

## Remove Behavior

The dashboard button says:

```text
Remove from board
```

This removes only the item reference from the board JSON. It does not delete, move, rename, copy, or approve any source asset.

## Safety Note

The dashboard shows:

```text
Reference boards store selected asset references only. They do not copy, move, delete, or approve source assets.
```

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api dashboard-ui
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards | jq .
```

### Open in browser
```text
http://127.0.0.1:8500
```

Expected:

- `Reference Boards` section is visible.
- Operators can create and select boards.
- Active board details and item count are visible.
- Output cards show `Add to board` only after a board is active.
- Board items show `Remove from board`.
- No delete, move, rename, copy, approve, generate, shell, or service-control buttons are present.

## What Is Not Implemented Yet

- No drag/drop ordering.
- No board export.
- No board rename.
- No dedicated board route.
- No reference-board asset copying.
- No source asset mutation.
