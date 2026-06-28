# Memory API

FastAPI service for the MoE Memory API.

This milestone connects Memory API to the fake Embed Worker backend and Qdrant. `POST /memory/add` stores fake embedding vectors in Qdrant and stores text, source, metadata, and `vector_id` in PostgreSQL. Real model inference and semantic search are not implemented yet.

## Local Development

From the repository root:

`make memory-dev`

The API listens on:

`http://127.0.0.1:8101`

## Health

`GET /health`

Expected response:

```json
{
  "service": "memory-api",
  "status": "ok",
  "dependencies": {
    "postgres": "configured",
    "qdrant": "configured",
    "embed_worker": "configured"
  }
}
```

## Deep Health

`GET /health/deep`

This endpoint attempts lightweight PostgreSQL, Qdrant, and Embed Worker connectivity checks. It reports `degraded` if a dependency is unavailable.

## Add Memory

`POST /memory/add`

Calls Embed Worker `/embed`, stores the vector in Qdrant, stores the memory row in PostgreSQL, and returns the created memory id plus `vector_id`.
