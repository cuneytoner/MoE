# Memory API

Milestone 4 adds configuration and infrastructure client layers to the Memory API.

The API is still intentionally limited to health and placeholder memory contracts. It can read PostgreSQL and Qdrant connection settings, and `/health/deep` can attempt lightweight connectivity checks. It does not create database tables, create Qdrant collections, implement embeddings, or persist memories yet.

## Service

- Name: `memory-api`
- Port: `8101`
- Framework: FastAPI
- ASGI server: Uvicorn
- Models: Pydantic

## Configuration

Settings are read from environment variables:

- `MEMORY_API_PORT`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `QDRANT_HOST`
- `QDRANT_PORT`
- `QDRANT_GRPC_PORT`

Documented local defaults live in `.env.example`.

## Endpoints

### GET /health

Response:

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

This endpoint does not open PostgreSQL or Qdrant connections.

### GET /health/deep

Response when dependencies are reachable:

```json
{
  "service": "memory-api",
  "status": "ok",
  "dependencies": {
    "postgres": "ok",
    "qdrant": "ok"
  }
}
```

If a dependency is unavailable, `status` is `degraded` and the dependency value includes the failure class.

### POST /memory/add

Request:

```json
{
  "text": "Memory text",
  "source": "optional source",
  "metadata": {
    "optional": "object"
  }
}
```

Temporary response:

```json
{
  "status": "accepted",
  "message": "memory add placeholder"
}
```

### POST /memory/search

Request:

```json
{
  "query": "search text",
  "limit": 5
}
```

Temporary response:

```json
{
  "status": "ok",
  "results": []
}
```

## Local Run

Install dependencies outside the repository source tree, then run:

`make memory-dev`

## Docker Compose

Build and start services:

`make docker-up`

Check the Memory API health endpoint:

`make memory-health`
