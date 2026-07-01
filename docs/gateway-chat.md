# Gateway Chat Proxy

Milestone 28.1 adds a minimal safe Gateway chat proxy at:

```text
POST /gateway/chat
```

The proxy accepts an OpenAI-like non-streaming chat request and forwards it to the host llama.cpp OpenAI-compatible runtime:

```text
LLAMA_SERVER_BASE_URL=http://host.docker.internal:8000
POST /v1/chat/completions
```

M28.3 also exposes OpenAI-compatible Gateway routes for clients such as Continue.dev:

```text
GET /v1/models
POST /v1/chat/completions
```

## Request

```json
{
  "messages": [
    {"role": "user", "content": "Say hello in one short sentence."}
  ],
  "temperature": 0.2,
  "max_tokens": 64,
  "routing": "auto",
  "stream": false
}
```

Allowed message roles are `system`, `user`, and `assistant`. Messages must be non-empty. `stream=true` returns HTTP 400 because streaming is not implemented in M28.1.

`routing` may be `auto` or `off`. The default is `auto`.

## Response

When llama-server is reachable:

```json
{
  "status": "ok",
  "service": "gateway-chat-proxy",
  "model": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
  "response": "Hello.",
  "router": {
    "intent": "general",
    "confidence": 0.35,
    "selected_model_id": "qwen-coder-14b-fast",
    "selected_model_path": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "active_model": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "active_model_matches": true,
    "mode": "advisory",
    "reasons": []
  },
  "raw": {}
}
```

When llama-server is unreachable:

```json
{
  "status": "unavailable",
  "service": "gateway-chat-proxy",
  "detail": "llama-server unavailable: ..."
}
```

The endpoint does not require an API key, does not execute shell commands, does not read or write workspace files, does not control Docker, and does not switch model runtime.

## Advisory Router

Milestone 28.2 adds deterministic advisory routing metadata. The router classifies messages into:

- `fast_code`
- `deep_code`
- `review_debug`
- `architecture`
- `general`

The router selects an advisory model id and path, reports the currently active llama-server model when available, and sets `active_model_matches`. This is informational only. Gateway does not start, stop, restart, or switch llama-server models.

When `routing="off"`, the router block uses `mode: "disabled"` and skips heuristic selection.

## Test

```bash
make test-openai-compatible-gateway
make test-gateway-chat-proxy
make test-gateway-chat-router
```

The test skips gracefully when Gateway or llama-server is unavailable and fails only when reachable services violate the contract.
