# Memory API

Milestone 3 adds the first Memory API skeleton.

The API is intentionally limited to health and placeholder memory contracts. It does not connect to PostgreSQL, Qdrant, embedding models, or runtime persistence yet.

## Service

- Name: `memory-api`
- Port: `8101`
- Framework: FastAPI
- ASGI server: Uvicorn
- Models: Pydantic

## Endpoints

### GET /health

Response:

```json
{
  "service": "memory-api",
  "status": "ok"
}
```

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
