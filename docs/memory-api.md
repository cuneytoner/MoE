# Memory API

Milestone 7 integrates the Memory API with the Embed Worker and Qdrant.

The API now requests deterministic fake embeddings from the Embed Worker, stores vectors in Qdrant, and stores text, source, metadata, and `vector_id` in PostgreSQL. Real model inference and semantic search ranking are not implemented yet.

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
- `EMBED_WORKER_INTERNAL_URL`

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
    "qdrant": "configured",
    "embed_worker": "configured"
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
    "qdrant": "ok",
    "embed_worker": "ok"
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
  "vector_id": "07a6d39f-68f2-4ea4-85fb-8e8f6b45b6bd",
  "message": "memory stored with embedding"
}
```

This endpoint calls the Embed Worker, ensures the Qdrant collection exists, inserts the vector into Qdrant, and inserts `text`, `source`, `metadata`, and `vector_id` into PostgreSQL.

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

Semantic search is not implemented yet. The endpoint keeps the stable placeholder response.

## Storage

PostgreSQL stores raw memory rows in the `memories` table:

- `id`
- `text`
- `source`
- `metadata`
- `vector_id`
- `created_at`
- `updated_at`

Qdrant stores fake embedding vectors with payload:

- `memory_id`
- `text`
- `source`
- `metadata`
- `created_at`

Qdrant defaults:

- Collection: `moe_memories`
- Embedding dimension: `384`

The Qdrant client checks reachability, creates the collection when needed, and upserts vectors from the fake Embed Worker backend.

Compatibility note:

The fake backend currently uses `384` dimensions, while local BGE-M3 currently returns `1024` dimensions. Future search work must validate Qdrant collection dimensions and avoid mixing `384` and `1024` vectors in the same collection.

## Local Run

Install dependencies outside the repository source tree, then run:

`make memory-dev`

## Docker Compose

Build and start services:

`make docker-up`

Check the Memory API health endpoint:

`make memory-health`
