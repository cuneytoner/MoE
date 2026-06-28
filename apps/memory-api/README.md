# Memory API

FastAPI skeleton for the MoE Memory API.

This milestone exposes health and placeholder memory contracts only. It does not connect to PostgreSQL, Qdrant, embedding models, or any persistence layer.

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
  "status": "ok"
}
```
