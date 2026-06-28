# Memory API

FastAPI skeleton for the MoE Memory API.

This milestone exposes health, dependency configuration, lightweight deep health checks, and placeholder memory contracts. It does not create database tables, create Qdrant collections, implement embeddings, or persist memories yet.

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
