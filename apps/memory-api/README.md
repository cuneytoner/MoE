# Memory API

FastAPI service for the MoE Memory API.

This milestone connects Memory API to the Embed Worker and Qdrant with dimension-aware collections. `POST /memory/add` stores vectors in a collection selected from the active embedding backend and vector dimension, and `POST /memory/search` embeds the query before searching the matching collection.

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

Calls Embed Worker `/embed`, stores the vector in Qdrant, stores the memory row in PostgreSQL, and returns the created memory id, `vector_id`, collection name, backend, and embedding dimension.

Default fake backend collection:

`moe_memories_fake_384`

Local BGE-M3 backend collection:

`moe_memories_bge_m3_1024`

## Search Memory

`POST /memory/search`

Embeds the query with the active Embed Worker backend, resolves the same collection name, and searches Qdrant. If the matching collection does not exist yet, the response is `ok` with an empty results array.
