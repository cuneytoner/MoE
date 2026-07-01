# Gateway Feedback Capture

Milestone 28.5 adds a safe feedback capture endpoint:

```text
POST /gateway/feedback
GET /gateway/feedback/status
```

Feedback is append-only JSONL written outside the repo:

```text
/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
```

## Request

```json
{
  "request_id": "optional",
  "response_id": "optional",
  "source": "manual",
  "rating": "useful",
  "reason": "Gateway answer was useful for the local MoE workflow.",
  "tags": ["m28", "gateway"],
  "router_intent": "architecture",
  "model": "gateway-auto"
}
```

Allowed `source` values:

- `continue`
- `gateway`
- `dashboard`
- `manual`
- `unknown`

Allowed `rating` values:

- `accepted`
- `rejected`
- `useful`
- `not_useful`
- `neutral`

Validation limits:

- `reason` max 1000 characters.
- `tags` max 20 items, each max 64 characters.
- `request_id` and `response_id` max 128 characters.

## Stored Record

Each JSONL record includes only feedback metadata:

```json
{
  "id": "...",
  "created_at": "...",
  "service": "gateway-feedback",
  "read_only_control_plane": true,
  "source": "manual",
  "rating": "useful",
  "reason": "...",
  "tags": ["m28"],
  "request_id": null,
  "response_id": null,
  "router_intent": "architecture",
  "model": "gateway-auto"
}
```

M28.5 does not store full prompt text or full response text.

## Status

`GET /gateway/feedback/status` returns aggregate file status only:

```json
{
  "status": "ok",
  "service": "gateway-feedback",
  "path": "/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl",
  "exists": true,
  "record_count": 3,
  "latest_created_at": "..."
}
```

It does not return feedback contents.

## Safety

- No shell execution.
- No Docker control.
- No model switching.
- No prompt or response body storage by default.
- Runtime feedback files stay under `/home/cuneyt/MoE/runtime`.
- The repo remains source-only.

## Smoke Test

```bash
make test-gateway-feedback
```
