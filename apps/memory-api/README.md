# Memory API

FastAPI skeleton for the MoE Memory API.

This milestone exposes health, dependency configuration, lightweight deep health checks, and PostgreSQL storage for raw memory text. It does not create Qdrant collections, implement embeddings, insert vectors, or perform semantic search yet.

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
    "qdrant": "configured"
  }
}
```

## Deep Health

`GET /health/deep`

This endpoint attempts lightweight PostgreSQL and Qdrant connectivity checks. It reports `degraded` if a dependency is unavailable.

## Add Memory

`POST /memory/add`

Stores `text`, `source`, and `metadata` in PostgreSQL and returns the created memory id. No embedding or Qdrant vector is created yet.
