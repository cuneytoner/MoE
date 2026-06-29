# Gateway API

Milestone 12 adds `gateway-api` as the single API entry point for local AI stack clients.

This is the first simple gateway. It does not implement the advanced MoE router and does not include Dashboard work.

## Service

- Name: `gateway-api`
- Port: `8100`
- Health endpoint: `GET /gateway/health`
- Host URL: `http://localhost:8100`

## Dependencies

Inside Docker Compose:

- Memory API: `http://memory-api:8101`
- Embed Worker: `http://embed-worker:8102`
- Model runtime: `http://host.docker.internal:8000/v1`

The model runtime runs on the host through llama.cpp, not in Docker. Compose uses:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Host examples and clients can use:

`http://localhost:8000/v1`

Current healthy runtime model:

`deepseek-coder-lite`

`qwen-coder-14b-fast` is temporarily unavailable until the local GGUF file is replaced and retested.

## Start

Start Docker services:

```bash
make docker-up
```

Start the host model runtime when chat/model calls are needed:

```bash
make model-start MODEL=deepseek-coder-lite
```

## Endpoints

### GET /gateway/health

Checks Memory API, Embed Worker, and model runtime best-effort. The Gateway service returns `status: ok` even when the model runtime is not running, with `model_runtime` marked unavailable.

### GET /gateway/models

Proxies the OpenAI-compatible model runtime `/models` endpoint.

```bash
curl -fsS http://localhost:8100/gateway/models | jq
```

If the model runtime is unavailable, this returns a controlled `503` with a clear detail message.

### POST /gateway/chat

Calls the OpenAI-compatible model runtime `/chat/completions` endpoint.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"hello","temperature":0.2,"max_tokens":128}' \
  http://localhost:8100/gateway/chat | jq
```

This endpoint is optional in default tests because it requires the host model runtime to be running and loaded.

### POST /gateway/route

Returns the first simple route decision:

```json
{
  "status": "ok",
  "intent": "chat",
  "model_target": "deepseek-coder-lite",
  "memory_enabled": false
}
```

Advanced MoE routing is intentionally left for a future milestone.

## Tests

Default Gateway tests:

```bash
make test-gateway
```

Optional runtime-dependent chat test:

```bash
make model-start MODEL=deepseek-coder-lite
make test-gateway-chat
```

Default `make test` does not require the host model runtime to be running.
