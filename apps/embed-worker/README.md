# Embed Worker

FastAPI service for the MoE Embed Worker.

This milestone supports the working `fake` backend and a safe `bge-m3` placeholder. It does not download models, load BGE-M3, run heavy inference, or write model files into the codebase.

## Local Development

From the repository root:

`cd apps/embed-worker && uvicorn app.main:app --host 0.0.0.0 --port 8102`

The service listens on:

`http://127.0.0.1:8102`

## Health

`GET /health`

Health reports the selected backend, embedding dimension, configured model path, whether that path exists, and model loading state.

## Embed

`POST /embed`

Request:

```json
{
  "text": "hello world"
}
```

The returned vector is deterministic and has length `EMBEDDING_DIM`.

With `EMBEDDING_BACKEND=bge-m3`, `/embed` returns HTTP 501 because real model loading is not implemented yet.
