# Gateway API

Milestone 12 adds `gateway-api` as the single API entry point for local AI stack clients.

This is the first simple gateway. It supports optional memory-augmented chat, but it does not implement the advanced MoE router and does not include Dashboard work.

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

Current healthy runtime models:

- `qwen-coder-14b-fast`: default advisory target
- `deepseek-coder-lite`: healthy fallback and ops target

## Start

Start Docker services:

```bash
make docker-up
```

Containers may report `health: starting` for a few seconds after a fresh build. The Gateway test script waits up to 30 seconds for `/gateway/health` before failing.

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

### GET /gateway/model-routing

Returns the loaded advisory model routing config:

```bash
curl -fsS http://localhost:8100/gateway/model-routing | jq
```

The config comes from `configs/model-routing.yaml`. It maps router intents to advisory model targets and runtime model ids. It does not restart or hot-switch llama.cpp.

### POST /gateway/chat

Calls the OpenAI-compatible model runtime `/chat/completions` endpoint.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"hello","temperature":0.2,"max_tokens":128}' \
  http://localhost:8100/gateway/chat | jq
```

Memory-augmented chat can be enabled per request:

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"What is my current local AI runtime model?","use_memory":true,"memory_limit":5,"temperature":0.2,"max_tokens":128}' \
  http://localhost:8100/gateway/chat | jq
```

When `use_memory` is true, Gateway searches Memory API with the chat message and `memory_limit`. If results are found, Gateway injects a concise system message:

`Use the following local memory only if relevant. If it is not relevant, ignore it.`

The injected context includes only compact memory text, source, and score when available. Gateway does not return the full raw memory payload by default.

If Memory API is unavailable or search fails, Gateway continues chat without memory and returns memory metadata with `status: unavailable`. If memory search succeeds but returns no results, the status is `empty`.

Router-aware chat is enabled by default with `auto_route: true`. Gateway calls the internal deterministic router directly and includes route metadata in the chat response:

```json
{
  "route": {
    "intent": "code",
    "confidence": 0.82,
    "model_target": "qwen-coder-14b-fast",
    "model_target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "model_mapping_status": "mapped",
    "use_memory_recommended": false,
    "reason": "Matched coding/debugging terms",
    "signals": {
      "matched_keywords": ["traceback", "error"],
      "message_length": 31
    }
  }
}
```

If `auto_route` is false, Gateway skips router-derived system prompt additions and preserves the older chat behavior as much as possible. Explicit `use_memory: true` still works.

When the router intent is `memory`, Gateway automatically enables memory search unless `use_memory` was already true. Other intents do not auto-enable memory yet.

Gateway adds one concise intent-specific system hint when `auto_route` is enabled:

- `chat`: answer naturally and concisely
- `code`: prefer precise, actionable coding help
- `memory`: use local memory only when relevant
- `review`: look for correctness, risks, missing cases, and improvements
- `ops`: prefer terminal-safe commands, verification, and rollback notes

`model_target` is advisory for now. Gateway does not hot-switch llama.cpp models in this milestone. If `model` is provided in the request, that model is sent to the OpenAI-compatible runtime. Otherwise Gateway keeps the current behavior: first model from `/models` when available, then `DEFAULT_MODEL`.

If the advisory target differs from the actual model used, the chat response includes `model_alignment`:

```json
{
  "model_alignment": {
    "target": "qwen-coder-32b-main",
    "target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf",
    "actual": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "matched": false,
    "reason": "Gateway does not switch runtime models yet"
  }
}
```

This endpoint is optional in default tests because it requires the host model runtime to be running and loaded.

### POST /gateway/route

Returns a deterministic intent-aware route decision. This router does not call an LLM; it uses readable keyword matching and simple confidence scoring.

```json
{
  "status": "ok",
  "intent": "code",
  "confidence": 0.82,
  "model_target": "qwen-coder-14b-fast",
  "model_target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
  "model_mapping_status": "mapped",
  "use_memory_recommended": false,
  "memory_enabled": false,
  "reason": "Matched coding/debugging terms",
  "signals": {
    "matched_keywords": ["traceback", "error"],
    "message_length": 31
  }
}
```

Supported intents:

- `chat`: general conversation fallback
- `code`: coding, debugging, implementation, refactors, tests
- `memory`: recall, remember, previous context, memory search
- `review`: code review, architecture, security, performance analysis
- `ops`: Docker, Linux, deployment, runtime, servers, network, logs

Current advisory model targets:

- `chat`: `qwen-coder-14b-fast`
- `code`: `qwen-coder-14b-fast`
- `memory`: `qwen-coder-14b-fast`
- `review`: `qwen-coder-32b-main`
- `ops`: `deepseek-coder-lite`

Future milestones can use these mappings to switch models or call tools, but this milestone only reports the advisory target.

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

Optional memory-augmented chat test:

```bash
make model-start MODEL=deepseek-coder-lite
make test-gateway-chat-memory
```

Optional router-aware chat test:

```bash
make model-start MODEL=qwen-coder-14b-fast
make test-gateway-chat-router
```

Default `make test` does not require the host model runtime to be running.
