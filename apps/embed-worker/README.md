# Embed Worker

FastAPI skeleton for the MoE Embed Worker.

This milestone uses a deterministic fake embedding backend only. It does not download models, load BGE-M3, run heavy inference, or write model files into the codebase.

## Local Development

From the repository root:

`cd apps/embed-worker && uvicorn app.main:app --host 0.0.0.0 --port 8102`

The service listens on:

`http://127.0.0.1:8102`

## Health

`GET /health`

## Embed

`POST /embed`

Request:

```json
{
  "text": "hello world"
}
```

The returned vector is deterministic and has length `EMBEDDING_DIM`.
