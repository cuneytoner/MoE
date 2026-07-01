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

## Request

```json
{
  "messages": [
    {"role": "user", "content": "Say hello in one short sentence."}
  ],
  "temperature": 0.2,
  "max_tokens": 64,
  "stream": false
}
```

Allowed message roles are `system`, `user`, and `assistant`. Messages must be non-empty. `stream=true` returns HTTP 400 because streaming is not implemented in M28.1.

## Response

When llama-server is reachable:

```json
{
  "status": "ok",
  "service": "gateway-chat-proxy",
  "model": "deepseek-coder-lite",
  "response": "Hello.",
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

The endpoint does not require an API key, does not execute shell commands, does not read or write workspace files, does not control Docker, and does not switch model runtime. M28.1 uses a small placeholder model chooser; M28.2 is reserved for richer model routing.

## Test

```bash
make test-gateway-chat-proxy
```

The test skips gracefully when Gateway or llama-server is unavailable and fails only when reachable services violate the contract.
