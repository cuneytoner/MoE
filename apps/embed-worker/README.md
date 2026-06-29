# Embed Worker

FastAPI service for the MoE Embed Worker.

This milestone supports the working `fake` backend and a lazy local `bge-m3` backend. It does not download models or write model files into the codebase.

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

With `EMBEDDING_BACKEND=bge-m3`, `/embed` loads the configured local model on first use and caches it in memory.
