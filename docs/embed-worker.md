# Embed Worker

Milestone 9 adds the real BGE-M3 embedding runtime.

The worker exposes a deterministic fake embedding backend and a lazy `bge-m3` backend. It never downloads models and never copies model files into the codebase.

Milestone 7 connects the Memory API to this fake backend. The backend remains fake and deterministic.

Current runtime issue:

Real BGE-M3 embedding can fail even when the configured path exists if the local model directory is incomplete or contains Git LFS pointer files. The next planning checkpoint adds explicit model integrity and Docker mount validation before relying on the real runtime in default workflows.

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

`/models/bge-m3`

Default host model backup directory:

`/home/cuneyt/MoE_Models_Backup`

This path is configuration only in this milestone. The model is not mounted into the container and is not loaded.

Supported backend values:

- `fake`: fully functional deterministic fake vectors.
- `bge-m3`: loads the local BGE-M3 model on the first `/embed` request and caches it in memory.

Current dimension behavior:

- `fake` uses the configured default `EMBEDDING_DIM=384`
- local `bge-m3` currently returns runtime-detected vectors with dimension `1024`

This means BGE-M3 validation is optional and separate from the default fake backend flow.

Docker mounts the local model read-only:

`${MODEL_BACKUP_DIR}/bge-m3:/models/bge-m3:ro`

Inside the container, `EMBEDDING_MODEL_PATH` is `/models/bge-m3`.

## Endpoints

### GET /health

Response:

```json
{
  "service": "embed-worker",
  "status": "ok",
  "backend": "fake",
  "embedding_dim": 384,
  "model_path": "/models/bge-m3",
  "model_path_exists": true,
  "model_loading": "not_required"
}
```

For `EMBEDDING_BACKEND=bge-m3`, `model_loading` is `lazy` and `model_loaded` reports whether the model is already cached in memory.

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

The fake response vector contains `EMBEDDING_DIM` float values. The same input text returns the same vector.

For `EMBEDDING_BACKEND=bge-m3`, this endpoint returns the actual model vector. The response `embedding_dim` is the actual vector length, not a hardcoded value.

## Tests

Default fake backend test:

`make test-embed`

Host-side test scripts use:

`EMBED_WORKER_URL=http://localhost:8102`

Optional BGE-M3 runtime test:

`RUN_BGE_M3_TEST=1 make test-embed`

Run the optional test only when the service is already running with `EMBEDDING_BACKEND=bge-m3` and the local model path is available.

Dedicated model integrity check:

`make check-models`

Dedicated optional BGE-M3 runtime check:

`make test-bge-m3`

Manual BGE-M3 Docker run:

`EMBEDDING_BACKEND=bge-m3 EMBEDDING_MODEL_PATH=/models/bge-m3 MODEL_BACKUP_DIR=/home/cuneyt/MoE_Models_Backup docker compose -f infra/docker/docker-compose.yml up -d --build embed-worker`

Return to fake default:

`docker compose -f infra/docker/docker-compose.yml up -d --build embed-worker`
