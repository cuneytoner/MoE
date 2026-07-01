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

Milestone 28.6 adds a Feedback Worker Bridge that can read this JSONL file and write an aggregate-only summary report. It does not learn, train, fine-tune, switch models, mutate memory, or control services.

Milestone 28.7 adds explicit user-run sync tooling for copying only Gateway feedback JSONL and the optional aggregate summary from PC1 to PC2. Dry-run is the default, and `APPLY=1` is required for an actual sync.

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

## Worker Bridge

Feedback Worker endpoints:

```text
GET /feedback/status
POST /feedback/summarize
```

Default input:

```text
/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
```

Default summary output:

```text
/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json
```

Environment overrides:

```text
FEEDBACK_JSONL_PATH=/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
FEEDBACK_SUMMARY_PATH=/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json
```

The summary includes counts for ratings, sources, router intents, models, tags, malformed lines, record totals, and latest timestamp. It does not include full reason text, raw prompt text, raw response text, or full feedback record bodies.

If the Feedback Worker runs on PC2 and the PC1 runtime path is not directly available, use the manual sync flow to copy `gateway-feedback.jsonl` into the PC2 runtime feedback directory before summarizing. The sync does not require always-on shared mounts.

## PC1 To PC2 Sync

```bash
make feedback-sync-status
make feedback-sync-to-pc2
APPLY=1 make feedback-sync-to-pc2
```

The sync copies only `gateway-feedback.jsonl` and `reports/feedback-summary.json` when present. It does not copy model files, media outputs, repository files, all runtime data, raw prompts, raw model responses, or logs. It does not delete remote files.

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
make feedback-summary-local
make test-feedback-worker-bridge
make feedback-sync-status
make feedback-sync-to-pc2
make test-feedback-sync
```
