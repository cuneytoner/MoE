# Reference Board API Implementation

## What Was Implemented

M34.11 adds safe Gateway API endpoints to list, read, and create reference boards.

The endpoints use the M34.16 safe runtime store helpers.

M34.17 extends reference boards with item selection endpoints.

M34.12 consumes these endpoints in the dashboard reference-board UI.

## Endpoints

```text
GET /gateway/media/reference-boards
GET /gateway/media/reference-boards/{board_id}
POST /gateway/media/reference-boards
```

## Request Example

```json
{
  "board_id": "api-test-board",
  "title": "API Test Board",
  "description": "Created by API smoke test."
}
```

The create endpoint does not accept `items` yet.

## Response Examples

List:

```json
{
  "status": "ok",
  "service": "gateway-reference-boards",
  "root": "/home/cuneyt/MoE/runtime/reference-boards",
  "boards": []
}
```

Create/read:

```json
{
  "status": "ok",
  "service": "gateway-reference-boards",
  "board": {
    "schema_version": "1.0",
    "board_id": "api-test-board",
    "title": "API Test Board",
    "items": []
  }
}
```

## Safety Rules

- Use board ids only.
- Do not accept arbitrary paths.
- Do not accept traversal.
- Do not accept asset paths in create.
- Do not copy, move, delete, or rename assets.
- Do not trigger generation.
- Do not execute shell commands.
- Do not expose model files.

## Runtime Folder

```text
/home/cuneyt/MoE/runtime/reference-boards
```

Gateway mounts only this reference-board runtime folder as writable for the new create endpoint.

## What Is Not Implemented Yet

- asset copy/move/delete
- generation
- reference-board export

Item selection is implemented in M34.17. Dashboard UI is implemented in M34.12. Export remains planned.

## How To Test

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards | jq .
```

### Run on PC-1
```bash
curl -fsS -X POST http://127.0.0.1:8100/gateway/media/reference-boards \
  -H 'Content-Type: application/json' \
  -d '{"board_id":"api-test-board","title":"API Test Board","description":"Created by API smoke test."}' | jq .
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board | jq .
```
