# Memory API

Milestone 5 adds the first storage foundation for the Memory API.

The API can persist raw memories to PostgreSQL. Qdrant configuration and reachability checks are present, but embeddings, vector inserts, vector search, and collection creation are not implemented yet.

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
- `QDRANT_COLLECTION`
- `EMBEDDING_DIM`

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

Response:

```json
{
  "status": "created",
  "id": "5b924f77-2c2f-45ed-a0df-9dfbfefae3f4",
  "message": "memory stored without embedding"
}
```

This endpoint inserts `text`, `source`, and `metadata` into PostgreSQL. It does not generate an embedding and does not insert a vector into Qdrant.

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

Semantic search is not implemented yet.

## Storage

PostgreSQL stores raw memory rows in the `memories` table:

- `id`
- `text`
- `source`
- `metadata`
- `vector_id`
- `created_at`
- `updated_at`

Qdrant defaults:

- Collection: `moe_memories`
- Embedding dimension placeholder: `384`

The Qdrant client can check reachability and exposes a placeholder `ensure_collection` function for future milestones.

## Local Run

Install dependencies outside the repository source tree, then run:

`make memory-dev`

## Docker Compose

Build and start services:

`make docker-up`

Check the Memory API health endpoint:

`make memory-health`
