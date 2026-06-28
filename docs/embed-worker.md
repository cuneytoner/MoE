# Embed Worker

Milestone 6 adds the Embed Worker service skeleton.

The worker exposes a deterministic fake embedding backend. It prepares the API shape and configuration for future local model integration, but it does not download models, load BGE-M3, run heavy inference, or copy model files into the codebase.

Milestone 7 connects the Memory API to this fake backend. The backend remains fake and deterministic.

## Service

- Name: `embed-worker`
- Port: `8102`
- Framework: FastAPI
- ASGI server: Uvicorn
- Models: Pydantic

## Configuration

Settings are read from environment variables:

- `EMBED_WORKER_HOST`
- `EMBED_WORKER_PORT`
- `EMBEDDING_BACKEND`
- `EMBEDDING_DIM`
- `EMBEDDING_MODEL_PATH`

Default model path:

`/home/cuneyt/MoE_Models_Backup/bge-m3`

This path is configuration only in this milestone. The model is not mounted into the container and is not loaded.

## Endpoints

### GET /health

Response:

```json
{
  "service": "embed-worker",
  "status": "ok",
  "backend": "fake",
  "embedding_dim": 384,
  "model_path_configured": true
}
```

### POST /embed

Request:

```json
{
  "text": "hello world"
}
```

Response:

```json
{
  "status": "ok",
  "backend": "fake",
  "embedding_dim": 384,
  "vector": []
}
```

The real response vector contains `EMBEDDING_DIM` float values. The same input text returns the same vector.
