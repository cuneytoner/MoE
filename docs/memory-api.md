# Memory API

Milestone 10 adds dimension-aware Qdrant collections and semantic search.

The API requests embeddings from the Embed Worker, reads the returned backend and vector dimension, stores vectors in a matching Qdrant collection, and searches only the matching collection. Fake vectors and BGE-M3 vectors are not mixed.

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
- `EMBED_WORKER_INTERNAL_URL`

Documented local defaults live in `.env.example`.

The Memory API does not use a fixed `QDRANT_COLLECTION` or configured embedding dimension. It resolves both from the Embed Worker `/embed` response.

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
  "collection_name": "moe_memories_fake_384",
  "embedding_backend": "fake",
  "embedding_dim": 384,
  "message": "memory stored with embedding"
}
```

This endpoint calls the Embed Worker, resolves the Qdrant collection from `backend` and `embedding_dim`, ensures that collection exists with the detected vector size, inserts the vector into Qdrant, and inserts memory metadata into PostgreSQL.

### POST /memory/search

Request:

```json
{
  "query": "search text",
  "limit": 5
}
```

Response:

```json
{
  "status": "ok",
  "collection_name": "moe_memories_fake_384",
  "embedding_backend": "fake",
  "embedding_dim": 384,
  "results": [
    {
      "id": "5b924f77-2c2f-45ed-a0df-9dfbfefae3f4",
      "vector_id": "07a6d39f-68f2-4ea4-85fb-8e8f6b45b6bd",
      "score": 0.91,
      "text": "Memory text",
      "source": "optional source",
      "metadata": {},
      "collection_name": "moe_memories_fake_384",
      "embedding_backend": "fake",
      "embedding_dim": 384
    }
  ]
}
```

This endpoint embeds the query through the active Embed Worker backend, resolves the same dimension-aware collection, and searches Qdrant using cosine distance. If the matching collection does not exist, the endpoint returns `status: ok` with an empty `results` array.

## Dimension-Aware Collections

Qdrant collections have a fixed vector size. A collection created for `384`-dimension fake vectors cannot accept or search `1024`-dimension BGE-M3 vectors. Mixing dimensions would fail at write or query time, so Memory API separates collections by backend and dimension.

Known collection names:

- Fake backend, `384` dimensions: `moe_memories_fake_384`
- BGE-M3 backend, `1024` dimensions: `moe_memories_bge_m3_1024`

If a future backend or dimension appears, Memory API uses the safe generated format:

`moe_memories_<normalized_backend>_<embedding_dim>`

Before writing or searching, Memory API validates that the target collection has the expected vector size. If an existing collection has an incompatible size, the API returns a controlled error instead of reusing it.

## Storage

PostgreSQL stores raw memory rows in the `memories` table:

- `id`
- `text`
- `source`
- `metadata`
- `vector_id`
- `collection_name`
- `embedding_backend`
- `embedding_dim`
- `created_at`
- `updated_at`

Existing dev databases may not have the Milestone 10 columns yet. Apply this idempotent migration to the running PostgreSQL container:

```bash
docker compose --env-file .env.example -f infra/docker/docker-compose.yml exec postgres psql -U moe -d moe -c "ALTER TABLE memories ADD COLUMN IF NOT EXISTS collection_name TEXT NULL, ADD COLUMN IF NOT EXISTS embedding_backend TEXT NULL, ADD COLUMN IF NOT EXISTS embedding_dim INTEGER NULL;"
```

This does not delete runtime data.

Qdrant stores fake embedding vectors with payload:

- `memory_id`
- `text`
- `source`
- `metadata`
- `collection_name`
- `embedding_backend`
- `embedding_dim`
- `created_at`

The Qdrant client checks reachability, creates collections when needed, validates vector size, upserts vectors, and searches the matching collection.

## Local Run

Install dependencies outside the repository source tree, then run:

`make memory-dev`

## Docker Compose

Build and start services:

`make docker-up`

Check the Memory API health endpoint:

`make memory-health`
