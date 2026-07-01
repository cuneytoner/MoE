# Gateway Memory Injection

Milestone 28.4 adds optional search-only memory injection for Gateway chat.

Supported routes:

```text
POST /gateway/chat
POST /v1/chat/completions
```

Both routes accept:

```json
{
  "memory": "auto",
  "memory_limit": 3
}
```

`memory` may be `auto` or `off`. The default is `auto`. `memory_limit` defaults to `3` and is capped at `8`.

## Behavior

When `memory="auto"`, Gateway extracts the latest user message and searches the fixed configured Memory API URL:

```text
MEMORY_SEARCH_URL=http://host.docker.internal:8101/search_memory
```

The Docker Compose Gateway service overrides the fallback to the current in-stack Memory API path:

```text
http://memory-api:8101/memory/search
```

If usable text results are returned, Gateway injects one bounded system message before the original conversation:

```text
Relevant local memory context:
[1] ...
[2] ...
Use this only if relevant. Do not claim memory if irrelevant.
```

The original user and assistant messages remain intact. Gateway does not store new memories in M28.4.

If memory is disabled, unavailable, empty, or malformed, chat continues without injected memory.

## Metadata

`/gateway/chat` includes:

```json
{
  "memory": {
    "mode": "auto",
    "status": "ok",
    "injected": true,
    "result_count": 2,
    "limit": 3,
    "detail": "bounded memory context injected"
  }
}
```

`/v1/chat/completions` keeps the OpenAI-compatible `choices[]` shape and adds:

```json
{
  "x_gateway_memory": {
    "mode": "auto",
    "status": "unavailable",
    "injected": false,
    "result_count": 0,
    "limit": 3
  }
}
```

Possible statuses are `ok`, `disabled`, `unavailable`, `empty`, and `error`.

## Safety

Gateway memory injection is read-only:

- No memory writes or storage.
- No user-provided memory service URL.
- No shell execution.
- No Docker control.
- No model switching.
- No full prompt logging by default.
- No raw private memory in response metadata.

The injected context is capped by `GATEWAY_MEMORY_CONTEXT_MAX_CHARS`, default `3000`.

## Smoke Test

```bash
make test-gateway-memory-injection
```

The test skips when Gateway or llama-server is unavailable. If memory search is unavailable but chat works, the test expects graceful memory metadata rather than failure.
