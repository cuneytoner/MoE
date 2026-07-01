# Feedback Worker Bridge

Milestone 28.6 extends `apps/feedback-worker` with a safe bridge for Gateway feedback JSONL.

## Endpoints

```text
GET /feedback/status
POST /feedback/summarize
```

`GET /feedback/status` reports file existence, valid record count, latest timestamp, and rating counts. Missing input files are allowed and return `exists=false`.

`POST /feedback/summarize` reads `FEEDBACK_JSONL_PATH`, ignores malformed lines while counting them, and writes aggregate metadata to `FEEDBACK_SUMMARY_PATH`.

## Paths

Defaults:

```text
FEEDBACK_JSONL_PATH=/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
FEEDBACK_SUMMARY_PATH=/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json
```

The output directory is created if missing. Reports must stay under runtime, not inside the repository.

## Summary Contents

The summary includes:

- `generated_at`
- `source_path`
- `record_count`
- `malformed_count`
- `rating_counts`
- `source_counts`
- `router_intent_counts`
- `model_counts`
- `top_tags`
- `latest_created_at`

It does not include full reason text, raw prompts, raw model responses, full feedback records, learning output, model changes, memory mutations, shell execution, Docker control, or service control.

## PC1 To PC2

Gateway feedback is created on PC1 under `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`. If the Feedback Worker runs on PC2 and that PC1 host path is not directly mounted, copy or sync the JSONL file into PC2's runtime feedback directory before running `/feedback/summarize`.

M28.6 intentionally does not require SSH, remote mounts, Docker socket access, or automatic copy behavior.

## Commands

```bash
make feedback-summary-local
make test-feedback-worker-bridge
```
